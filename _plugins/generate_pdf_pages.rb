# frozen_string_literal: true

# Jekyll plugin to generate index.html pages for each paper in _data/papers.yml
# Output: /:name/index.html (where :name is the base name of the PDF file, without extension)

require 'fileutils'
require 'json'

module Jekyll
  class PDFPage < Page
  def initialize(site, base, dir, paper, source_section)
      @site = site
      @base = base
      @dir  = dir
      @name = 'index.html'

      self.process(@name)
      self.data = paper.dup
      self.data['layout'] = nil # No layout, pure HTML
      pdf_basename = File.basename(paper['file'].sub(/^\//, ''))
      # Compose authors: always include yourself, and look up full names from coauthors.yml
      coauthors = site.data['coauthors'] || {}
      authors = ["Hassan Afrouzi"]
      if paper['authors']
        keys = paper['authors'].is_a?(Array) ? paper['authors'] : [paper['authors']]
        keys.each do |key|
          if coauthors[key] && coauthors[key]['name']
            authors << coauthors[key]['name']
          else
            authors << key # fallback to key if not found
          end
        end
      end
      authors = authors.uniq
      meta_authors = authors.join(', ')
      meta_version = paper['version'] ? paper['version'] : nil
      meta_journal = (source_section == 'publications' && paper['journal']) ? paper['journal'] : nil
      meta_tags = "<meta name=\"author\" content=\"#{meta_authors}\">\n"
      meta_tags += "<meta name=\"version\" content=\"#{meta_version}\">\n" if meta_version
      meta_tags += "<meta name=\"journal\" content=\"#{meta_journal}\">\n" if meta_journal
      redirect_url = "/#{pdf_basename}"
      site_url = site.config['url'] || ''
      full_url = site_url.chomp('/') + redirect_url

      # Build SEO tags (description, canonical/alternate, OG/Twitter) and JSON-LD
      site_title = site.config['title']
      description_text = "#{paper['title']} — #{meta_authors}#{meta_journal ? " — #{meta_journal}" : ''}"
      seo_tags = String.new
      seo_tags << "<link rel=\"canonical\" href=\"#{full_url}\">\n"
      seo_tags << "<link rel=\"alternate\" type=\"application/pdf\" href=\"#{full_url}\">\n"
      seo_tags << "<meta name=\"description\" content=\"#{description_text}\">\n"
      seo_tags << "<meta property=\"og:title\" content=\"#{paper['title']}\">\n"
      seo_tags << "<meta property=\"og:description\" content=\"#{description_text}\">\n"
      seo_tags << "<meta property=\"og:type\" content=\"article\">\n"
      seo_tags << "<meta property=\"og:url\" content=\"#{full_url}\">\n"
      seo_tags << "<meta property=\"og:site_name\" content=\"#{site_title}\">\n" if site_title
      seo_tags << "<meta name=\"twitter:card\" content=\"summary\">\n"
      seo_tags << "<meta name=\"twitter:title\" content=\"#{paper['title']}\">\n"
      seo_tags << "<meta name=\"twitter:description\" content=\"#{description_text}\">\n"

      jsonld = {
        "@context" => "https://schema.org",
        "@type" => "ScholarlyArticle",
        "name" => paper['title'],
        "author" => authors.map { |n| { "@type" => "Person", "name" => n } },
        "url" => full_url,
        "isAccessibleForFree" => true
      }
      jsonld["dateModified"] = meta_version if meta_version
      if meta_journal
        jsonld["isPartOf"] = { "@type" => "Periodical", "name" => meta_journal }
      end
      jsonld_script = "<script type=\"application/ld+json\">#{JSON.generate(jsonld)}</script>\n"

      analytics = ''
      if site.config.dig('compass', 'include_analytics')
        analytics = '{% include analytics.html %}'
      end
      self.content = <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta http-equiv="refresh" content="0; url=#{redirect_url}">
          <title>#{paper['title']}</title>
          #{meta_tags}
          #{seo_tags}
          #{jsonld_script}
          #{analytics}
        </head>
        <body>
          Opening the PDF file for <strong>#{paper['title']}</strong> by <strong>#{meta_authors}</strong> at <a href="#{full_url}">#{full_url}</a>.<br>
          If the PDF fails to open, please access it using the link above.
        </body>
        </html>
      HTML
    end
  end

  class GeneratePDFPages < Generator
    safe true
    priority :low

    def generate(site)
      papers = site.data['papers']
      return unless papers
      all_papers = []
      paper_sources = []
      if papers['working_papers']
        papers['working_papers'].each { |p| all_papers << p; paper_sources << 'working_papers' }
      end
      if papers['publications']
        papers['publications'].each { |p| all_papers << p; paper_sources << 'publications' }
      end
      # Do NOT add work_in_progress papers
      all_papers.each_with_index do |paper, idx|
        next unless paper['file'] && paper['file'].end_with?('.pdf')
        pdf_path = paper['file'].sub(/^\//, '')
        name = File.basename(pdf_path, '.pdf')
        site.pages << PDFPage.new(site, site.source, name, paper, paper_sources[idx])
      end
    end
  end
end
