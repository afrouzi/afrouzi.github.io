require 'json'
require 'uri'
require 'date'

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

			description_text = "#{paper['title']} — #{meta_authors}#{meta_journal ? " — #{meta_journal}" : ''}"
			site_title = site.config['title']

			meta_tags = String.new
			meta_tags << "<meta name=\"author\" content=\"#{meta_authors}\">\n"
			meta_tags << "<meta name=\"journal\" content=\"#{meta_journal}\">\n" if meta_journal
			meta_tags << "<meta name=\"dateModified\" content=\"#{meta_lastmod}\">\n" if meta_lastmod

			seo_tags = String.new
			canonical_url = (source_section == 'publications') ? full_redirect : slug_url
			seo_tags << "<link rel=\"canonical\" href=\"#{canonical_url}\">\n"
			seo_tags << "<meta name=\"description\" content=\"#{description_text}\">\n"
			seo_tags << "<meta property=\"og:title\" content=\"#{paper['title']}\">\n"
			seo_tags << "<meta property=\"og:description\" content=\"#{description_text}\">\n"
			seo_tags << "<meta property=\"og:type\" content=\"article\">\n"
			seo_tags << "<meta property=\"og:url\" content=\"#{canonical_url}\">\n"
			seo_tags << "<meta property=\"og:site_name\" content=\"#{site_title}\">\n" if site_title
			seo_tags << "<meta name=\"twitter:card\" content=\"summary\">\n"
			seo_tags << "<meta name=\"twitter:title\" content=\"#{paper['title']}\">\n"
			seo_tags << "<meta name=\"twitter:description\" content=\"#{description_text}\">\n"

			jsonld = {
				"@context" => "https://schema.org",
				"@type" => "ScholarlyArticle",
				"name" => paper['title'],
				"author" => authors.map { |n| { "@type" => "Person", "name" => n } },
				"url" => (source_section == 'publications') ? full_redirect : slug_url,
				"isAccessibleForFree" => true
			}
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
						#{meta_tags}
						#{seo_tags}
						#{jsonld_script}
						#{analytics}
					</head>
					<body>
						Redirecting to <a href="#{full_redirect}">#{full_redirect}</a>.
					</body>
					</html>
				HTML
			else
				# For working papers, embed the PDF so the slug stays in the address bar
				# Compute human-friendly last updated
				display_lastmod = nil
				if meta_lastmod && meta_lastmod =~ /\A\d{4}-\d{2}-\d{2}\z/
					begin
						display_lastmod = Date.strptime(meta_lastmod, '%Y-%m-%d').strftime('%B %Y')
					rescue
						display_lastmod = meta_lastmod
					end
				elsif file_url && file_url.start_with?('/')
					pdf_path = File.join(site.source, file_url.sub(/^\//, ''))
					if File.exist?(pdf_path)
						display_lastmod = File.mtime(pdf_path).strftime('%B %Y')
					end
				end

				adobe_client_id = site.config['adobe_pdf_client_id']
				adobe_div_id = "adobe-dc-view"
				adobe_script = if adobe_client_id && !adobe_client_id.to_s.strip.empty? && file_url
					<<~AS
					<script src="https://documentcloud.adobe.com/view-sdk/main.js"></script>
					<script>
					(function(){
					  if (window.matchMedia && window.matchMedia('(max-width: 700px)').matches) return; // mobile handled by redirect
					  document.addEventListener('adobe_dc_view_sdk.ready', function(){
					    try {
					      var view = new AdobeDC.View({clientId: '#{adobe_client_id}', divId: '#{adobe_div_id}'});
					      view.previewFile({content:{location:{url:'#{file_url}'}}, metaData:{fileName: '#{paper['title']}.pdf'}},{
					        defaultViewMode: "CONTINUOUS"
					      });
					    } catch(e) { /* ignore */ }
					  });
					})();
					</script>
					AS
					else
						""
					end
				iframe_html = if file_url
					if adobe_client_id && !adobe_client_id.to_s.strip.empty?
						"<div id=\"#{adobe_div_id}\" style=\"width:100%;height:100%;\"></div>#{adobe_script}"
					else
						"<iframe src=\"#{file_url}#page=1&zoom=page-fit\" title=\"#{paper['title']}\" loading=\"lazy\"></iframe>"
					end
				else
					"<p>PDF not available.</p>"
				end

				mobile_redirect_script = file_url ? "<script>(function(){try{if(window.matchMedia&&window.matchMedia('(max-width: 700px)').matches){window.location.replace('#{file_url}');}}catch(e){}})();</script>" : ""
				self.content = <<~HTML
					<!DOCTYPE html>
					<html lang="en">
					<head>
						<meta name="viewport" content="width=device-width, initial-scale=1">
						<link href="https://fonts.googleapis.com/css2?family=Source+Sans+Pro:wght@300;400;600;700;900&display=swap" rel="stylesheet">
						<script src="https://kit.fontawesome.com/9800a0f763.js" crossorigin="anonymous"></script>
						<link rel="stylesheet" href="/assets/main.css?v={{ site.time | date: '%s' }}">
						<title>#{paper['title']}</title>
						#{meta_tags}
						#{seo_tags}
						#{jsonld_script}
						#{analytics}
						#{mobile_redirect_script}
					</head>
					<body class="embed-root">
						<div class="pdf-frame">
							#{file_url ? "<a class=\"pdf-download-fab\" href=\"#{file_url}\" rel=\"nofollow\" download><i class=\"fas fa-download\" aria-hidden=\"true\"></i> Download PDF</a>" : ""}
							#{iframe_html}
						</div>
					</body>
					</html>
				HTML
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

