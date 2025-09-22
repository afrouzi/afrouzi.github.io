require 'json'
require 'uri'
require 'date'
require 'cgi'

module Jekyll
	class PDFPage < Page
		def initialize(site, base, dir, paper, source_section)
			@site = site
			@base = base
			@dir  = dir
			@name = 'index.html'

			process(@name)
			self.data = paper.dup
			self.data['layout'] = nil

			coauthors = site.data['coauthors'] || {}
			authors = ["Hassan Afrouzi"]
			if paper['authors']
				Array(paper['authors']).each do |key|
					authors << (coauthors.dig(key, 'name') || key)
				end
			end
			authors = authors.uniq
			meta_authors = authors.join(', ')
			meta_journal = (source_section == 'publications' && paper['journal']) ? paper['journal'] : nil
			meta_lastmod = paper['lastmod']
			# Abstract (from _data/papers.yml); used for SEO when present
			raw_abstract = (paper['abstract'] || '').to_s.strip
			abstract_text = raw_abstract.gsub(/\s+/, ' ')
			# Build a concise description: prefer abstract, else fallback to title + authors (+ journal)
			fallback_desc = "#{paper['title']} — #{meta_authors}#{meta_journal ? " — #{meta_journal}" : ''}"
			meta_description = if abstract_text.empty?
				fallback_desc
			else
				# Truncate abstract to ~300 chars to fit meta contexts
				maxlen = 300
				abstract_text.length > maxlen ? abstract_text[0...maxlen].rstrip + '…' : abstract_text
			end


			raw_file = paper['file'] ? paper['file'].to_s : nil
			file_url = nil
			if raw_file && !raw_file.empty?
				if raw_file =~ /\Ahttps?:\/\//i
					file_url = raw_file
				else
					file_url = raw_file.start_with?('/') ? raw_file : "/#{raw_file}"
				end
			end

			# URLs
			site_url = site.config['url'] || ''
			# Slug page absolute URL
			slug_url = site_url.chomp('/') + "/#{@dir}/"
			# Publications redirect target (homepage search); Working papers show embedded PDF
			redirect_path = nil
			if source_section == 'publications'
				q = URI.encode_www_form_component(paper['title'] || '')
				redirect_path = "/?q=#{q}"
			end
			full_redirect = redirect_path ? (site_url.chomp('/') + redirect_path) : nil
			full_pdf = nil
			if file_url
				full_pdf = if file_url =~ /\Ahttps?:\/\//i
					file_url
				else
					site_url.chomp('/') + file_url
				end
			end

			site_title = site.config['title']

			# Prefer explicit year if present; else parse trailing (YYYY) from details
			pub_year = nil
			if paper['year']
				pub_year = paper['year'].to_s[/\d{4}/]
			elsif paper['details']
				m = paper['details'].to_s.match(/\((\d{4})\)\s*$/)
				pub_year = m[1] if m
			end

			# Canonical URL for this page (publications redirect to a search URL)
			canonical_url = (source_section == 'publications') ? full_redirect : slug_url

			# Build a single ordered block of head tags (deduplicated)
			head_tags = String.new
			head_tags << "<link rel=\"canonical\" href=\"#{canonical_url}\">\n"
			# For working papers, advertise the PDF as an alternate format
			if source_section != 'publications' && full_pdf
				head_tags << "<link rel=\"alternate\" type=\"application/pdf\" href=\"#{full_pdf}\">\n"
			end
			# Core description and attribution
			head_tags << "<meta name=\"description\" content=\"#{CGI.escapeHTML(meta_description)}\">\n"
			head_tags << "<meta name=\"author\" content=\"#{CGI.escapeHTML(meta_authors)}\">\n"
			# Highwire citation tags (for academic indexers)
			head_tags << "<meta name=\"citation_title\" content=\"#{CGI.escapeHTML(paper['title'].to_s)}\">\n"
			authors.each { |a| head_tags << "<meta name=\"citation_author\" content=\"#{CGI.escapeHTML(a)}\">\n" }
			head_tags << "<meta name=\"citation_journal_title\" content=\"#{CGI.escapeHTML(meta_journal)}\">\n" if meta_journal
			if paper['doi']
				doi_val = paper['doi'].to_s
				head_tags << "<meta name=\"citation_doi\" content=\"#{CGI.escapeHTML(doi_val)}\">\n"
			end
			head_tags << "<meta name=\"citation_publication_date\" content=\"#{pub_year}\">\n" if pub_year
			head_tags << "<meta name=\"citation_pdf_url\" content=\"#{CGI.escapeHTML(full_pdf)}\">\n" if full_pdf
			head_tags << "<meta name=\"citation_abstract\" content=\"#{CGI.escapeHTML(abstract_text)}\">\n" unless abstract_text.empty?
			# Open Graph
			head_tags << "<meta property=\"og:title\" content=\"#{CGI.escapeHTML(paper['title'].to_s)}\">\n"
			head_tags << "<meta property=\"og:description\" content=\"#{CGI.escapeHTML(meta_description)}\">\n"
			head_tags << "<meta property=\"og:type\" content=\"article\">\n"
			head_tags << "<meta property=\"og:url\" content=\"#{canonical_url}\">\n"
			head_tags << "<meta property=\"og:site_name\" content=\"#{site_title}\">\n" if site_title
			head_tags << "<meta property=\"article:published_time\" content=\"#{pub_year}-01-01\">\n" if pub_year
			head_tags << "<meta property=\"article:modified_time\" content=\"#{meta_lastmod}\">\n" if meta_lastmod
			head_tags << "<meta property=\"og:updated_time\" content=\"#{meta_lastmod}\">\n" if meta_lastmod
			# Twitter
			head_tags << "<meta name=\"twitter:card\" content=\"summary\">\n"
			head_tags << "<meta name=\"twitter:title\" content=\"#{CGI.escapeHTML(paper['title'].to_s)}\">\n"
			head_tags << "<meta name=\"twitter:description\" content=\"#{CGI.escapeHTML(meta_description)}\">\n"

			jsonld = {
				"@context" => "https://schema.org",
				"@type" => "ScholarlyArticle",
				"name" => paper['title'],
				"author" => authors.map { |n| { "@type" => "Person", "name" => n } },
				"url" => (source_section == 'publications') ? full_redirect : slug_url,
				"isAccessibleForFree" => true,
				"description" => meta_description
			}
			if pub_year
				# Use Jan 1st as an approximate publication date when only year is known
				jsonld["datePublished"] = sprintf("%s-01-01", pub_year)
			end
			jsonld["abstract"] = abstract_text unless abstract_text.empty?
			if file_url && full_pdf
				jsonld["encoding"] = {
					"@type" => "MediaObject",
					"contentUrl" => full_pdf,
					"fileFormat" => "application/pdf"
				}
			end
			if meta_lastmod && meta_lastmod =~ /\A\d{4}-\d{2}-\d{2}\z/
				jsonld["dateModified"] = meta_lastmod
			elsif file_url && file_url.start_with?('/')
				pdf_path = File.join(site.source, file_url.sub(/^\//, ''))
				if File.exist?(pdf_path)
					jsonld["dateModified"] = File.mtime(pdf_path).strftime('%Y-%m-%d')
				end
			end
			if paper['doi']
				doi_url = paper['doi'].start_with?('http') ? paper['doi'] : "https://doi.org/#{paper['doi']}"
				jsonld["identifier"] = doi_url
				jsonld["sameAs"] = doi_url
			end
			if meta_journal
				jsonld["isPartOf"] = { "@type" => "Periodical", "name" => meta_journal }
			end
			jsonld_script = "<script type=\"application/ld+json\">#{JSON.generate(jsonld)}</script>\n"

			analytics = ''
			analytics = '{% include analytics.html %}' if site.config.dig('compass', 'include_analytics')

			if source_section == 'publications'
				# Keep redirect behavior for publications
				self.content = <<~HTML
					<!DOCTYPE html>
					<html lang="en">
					<head>
						<script src="https://kit.fontawesome.com/9800a0f763.js" crossorigin="anonymous"></script>
						<meta http-equiv="refresh" content="0; url=#{redirect_path}">
						<title>#{paper['title']}</title>
						#{head_tags}
						#{jsonld_script}
						#{analytics}
					</head>
					<body>
						Redirecting to <a href="#{full_redirect}">#{full_redirect}</a>.
					</body>
					</html>
				HTML
			else
				# For working papers, embed the PDF using Mozilla PDF.js viewer
				if file_url
					# Use a same-origin path for the viewer when possible to avoid CORS during local dev
					file_for_viewer = if file_url && file_url.start_with?('/')
						file_url
					else
						full_pdf || file_url
					end
					viewer_src = "/assets/pdfjs/viewer.html?file=#{URI.encode_www_form_component(file_for_viewer)}#pagemode=none"
					self.content = <<~HTML
						<!DOCTYPE html>
						<html lang="en">
						<head>
							<meta charset="utf-8">
							<meta name="viewport" content="width=device-width, initial-scale=1">
							<title>#{paper['title']}</title>
							#{head_tags}
							#{jsonld_script}
							#{analytics}
							<style>html,body{height:100%;margin:0;background:#f6faef} .viewer-frame{position:fixed;inset:0;border:0;width:100%;height:100%}</style>
						</head>
						<body>
							<iframe class="viewer-frame" src="#{viewer_src}" title="#{paper['title']}" allow="fullscreen"></iframe>
														<script>
														(function(){
															function isCombo(e, code){
																const k=e.key||e.keyCode; const match=(k===code||(typeof k==='string'&&k.toLowerCase()===String.fromCharCode(code).toLowerCase()));
																return match && (e.metaKey||e.ctrlKey);
															}
															function isSaveCombo(e){ return isCombo(e,83); }
															function isFindCombo(e){ return isCombo(e,70); }
															function withViewer(fn){
																const iframe=document.querySelector('.viewer-frame');
																if(!iframe||!iframe.contentWindow) return false;
																try{ return fn(iframe.contentWindow)===true; }catch(_){ return false; }
															}
															function triggerDownload(){
																return withViewer(w=>{
																	if(w.PDFViewerApplication?.download){ w.PDFViewerApplication.download(); return true; }
																	const btn=w.document.getElementById('downloadButton'); if(btn){ btn.click(); return true; }
																	return false;
																});
															}
															function triggerFind(){
																return withViewer(w=>{
																	if(w.PDFViewerApplication?.findBar?.open){ w.PDFViewerApplication.findBar.open();
																		const input=w.document.getElementById('findInput'); input?.focus(); input?.select(); return true; }
																	const btn=w.document.getElementById('viewFindButton'); if(btn){ btn.click(); return true; }
																	return false;
																});
															}
															window.addEventListener('keydown', function(e){
																if(isSaveCombo(e)){
																	if(triggerDownload()){ e.preventDefault(); e.stopPropagation(); }
																	return;
																}
																if(isFindCombo(e)){
																	if(triggerFind()){ e.preventDefault(); e.stopPropagation(); }
																}
															}, true);
														})();
														</script>
						</body>
						</html>
					HTML
				else
					self.content = <<~HTML
						<!DOCTYPE html>
						<html lang="en">
						<head>
							<meta charset="utf-8">
							<meta name="viewport" content="width=device-width, initial-scale=1">
							<title>#{paper['title']}</title>
							#{head_tags}
							#{jsonld_script}
							#{analytics}
						</head>
						<body>
							<p>PDF not available.</p>
						</body>
						</html>
					HTML
				end
			end
		end
	end

	class GeneratePDFPages < Generator
		safe true
		priority :low

		def generate(site)
			papers = site.data['papers']
			return unless papers
			all = []
			src = []
			if papers['working_papers']
				papers['working_papers'].each { |p| all << p; src << 'working_papers' }
			end
			if papers['publications']
				papers['publications'].each do |p|
					all << p
					src << 'publications'
					# If publication has a Working Paper Version link, generate a subpage under slug/working-paper/
					wp_link = nil
					if p['extra_links']
						Array(p['extra_links']).each do |group|
							Array(group['links']).each do |lnk|
								label = (lnk['label'] || '').to_s.downcase.strip
								if label == 'working paper version'
									wp_link = lnk['url']
									break
								end
							end
							break if wp_link
						end
					end
					if wp_link
						# Derive slug from publication and create a synthetic paper object for the subpage
						slug = if p['slug'] && !p['slug'].to_s.strip.empty?
							p['slug'].to_s.strip
						elsif p['title']
							t = p['title'].to_s.downcase
							t.gsub(/[^a-z0-9]+/, '-').gsub(/^-+|-+$/, '')
						end
						if slug
							wp_paper = p.dup
							wp_paper['title'] = "#{p['title']} — Working Paper Version"
							wp_paper['file'] = wp_link
							wp_slug_dir = File.join(slug, 'working-paper')
							# Inject a one-off page for this working-paper view
							site.pages << PDFPage.new(site, site.source, wp_slug_dir, wp_paper, 'working_papers')
						end
					end
				end
			end
			all.each_with_index do |paper, i|
				# Slug only
				slug = if paper['slug'] && !paper['slug'].to_s.strip.empty?
								 paper['slug'].to_s.strip
							 elsif paper['title']
								 t = paper['title'].to_s.downcase
								 t.gsub(/[^a-z0-9]+/, '-').gsub(/^-+|-+$/, '')
							 end
				next unless slug
				site.pages << PDFPage.new(site, site.source, slug, paper, src[i])
			end
		end
	end
end

