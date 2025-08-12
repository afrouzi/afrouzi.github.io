# frozen_string_literal: true

# Jekyll plugin to generate an index.html page for cv.pdf with metadata and latest modified date

require 'fileutils'
require 'json'

module Jekyll
  class CVPage < Page
    def initialize(site, base, dir, cv_path, last_modified)
      @site = site
      @base = base
      @dir  = dir
      @name = 'index.html'

      # Ensure the directory exists in the destination
      dest_dir = File.join(site.dest, dir)
      FileUtils.mkdir_p(dest_dir) unless Dir.exist?(dest_dir)

      self.process(@name)
      self.data = {
        'layout' => nil,
        'title' => 'Curriculum Vitae',
        'file' => cv_path,
        'last_updated' => last_modified
      }
      redirect_url = '/cv.pdf'
      site_url = site.config['url'] || ''
      baseurl = site.config['baseurl'] || ''
      full_url = site_url.chomp('/') + redirect_url
      homepage_url = site_url.chomp('/') + baseurl + '/'

      # SEO and social tags
      site_title = site.config['title']
      description_text = "Curriculum Vitae — Hassan Afrouzi (Last updated: #{last_modified})"
      seo_tags = String.new
      seo_tags << "<link rel=\"canonical\" href=\"#{full_url}\">\n"
      seo_tags << "<link rel=\"alternate\" type=\"application/pdf\" href=\"#{full_url}\">\n"
      seo_tags << "<meta property=\"og:title\" content=\"Curriculum Vitae\">\n"
      seo_tags << "<meta property=\"og:description\" content=\"#{description_text}\">\n"
      seo_tags << "<meta property=\"og:type\" content=\"article\">\n"
      seo_tags << "<meta property=\"og:url\" content=\"#{full_url}\">\n"
      seo_tags << "<meta property=\"og:site_name\" content=\"#{site_title}\">\n" if site_title
      seo_tags << "<meta name=\"twitter:card\" content=\"summary\">\n"
      seo_tags << "<meta name=\"twitter:title\" content=\"Curriculum Vitae\">\n"
      seo_tags << "<meta name=\"twitter:description\" content=\"#{description_text}\">\n"

      # Additional Person JSON-LD (like in head) for stronger entity linking
      compass = site.config['compass'] || {}
      person_name = compass['author'] || 'Hassan Afrouzi'
      default_same_as = [
        'https://scholar.google.com/citations?user=mnxLP9YAAAAJ&hl=en&oi=ao',
        'https://www.nber.org/people/hassan_afrouzi?page=1&perPage=50',
        'https://econ.columbia.edu/econpeople/hassan-afrouzi/'
      ]
      same_as = compass['same_as'] if compass['same_as'].is_a?(Array)
      same_as = default_same_as if !same_as || same_as.empty?

      person_json = {
        "@context" => "https://schema.org",
        "@type" => "Person",
        "name" => person_name,
        "url" => homepage_url
      }
      person_json["sameAs"] = same_as if same_as && !same_as.empty?
      person_jsonld_script = "<script type=\"application/ld+json\">#{JSON.generate(person_json)}</script>\n"

      analytics = ''
      if site.config.dig('compass', 'include_analytics')
        analytics = '{% include analytics.html %}'
      end
      self.content = <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta http-equiv="refresh" content="0; url=#{redirect_url}">
          <title>Curriculum Vitae</title>
          <meta name="description" content="Academic CV for Afrouzi. Last updated: #{last_modified}">
          #{seo_tags}
          #{person_jsonld_script}
          #{analytics}
        </head>
        <body>
          Opening the PDF file for <strong>Hassan Afrouzi's</strong> CV (last updated: <strong>#{last_modified}</strong>) at <a href="#{full_url}">#{full_url}</a>.<br>
          If the PDF fails to open, please access it using the link above.
        </body>
        </html>
      HTML
    end
  end

  class GenerateCVPage < Generator
    safe true
    priority :low

    def generate(site)
      cv_path = '_files/cv.pdf'
      abs_cv_path = File.join(site.source, cv_path)
      if File.exist?(abs_cv_path)
        last_modified = File.mtime(abs_cv_path).strftime('%Y-%m-%d')
        site.pages << CVPage.new(site, site.source, 'cv', cv_path, last_modified)
      end
    end
  end
end
