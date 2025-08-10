# frozen_string_literal: true

# Jekyll plugin to generate an index.html page for cv.pdf with metadata and latest modified date

require 'fileutils'

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
      full_url = site_url.chomp('/') + redirect_url
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
          #{analytics}
        </head>
        <body>
          Opening <strong>Hassan Afrouzi's</strong> CV (last updated: <strong>#{last_modified}</strong>).<br>
          If the PDF fails to open, please access it at <a href="#{full_url}">#{full_url}</a>.
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
