# frozen_string_literal: true

# Jekyll plugin to generate an index.html page for cv.pdf with metadata and latest modified date

require 'fileutils'
require 'json'
require 'date'

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
      compass = site.config['compass'] || {}
      person_name = compass['author'] || 'Hassan Afrouzi'
      self.data = {
        'layout' => nil,
        'title' => "Curriculum Vitae — #{person_name}",
        'file' => cv_path,
        'last_updated' => last_modified
      }
  file_url = '/cv.pdf'
  site_url = site.config['url'] || ''
  baseurl = site.config['baseurl'] || ''
  slug_url = site_url.chomp('/') + baseurl + '/cv/'
  full_pdf = site_url.chomp('/') + file_url
  homepage_url = site_url.chomp('/') + baseurl + '/'

      # SEO and social tags
      site_title = site.config['title']
      description_text = "Curriculum Vitae — #{person_name}"
  seo_tags = String.new
  seo_tags << "<link rel=\"canonical\" href=\"#{slug_url}\">\n"
  seo_tags << "<link rel=\"alternate\" type=\"application/pdf\" href=\"#{full_pdf}\">\n"
  seo_tags << "<meta property=\"og:title\" content=\"Curriculum Vitae\">\n"
  seo_tags << "<meta property=\"og:description\" content=\"#{description_text}\">\n"
  seo_tags << "<meta property=\"og:type\" content=\"article\">\n"
  seo_tags << "<meta property=\"og:url\" content=\"#{slug_url}\">\n"
  seo_tags << "<meta property=\"og:site_name\" content=\"#{site_title}\">\n" if site_title
  seo_tags << "<meta name=\"twitter:card\" content=\"summary\">\n"
  seo_tags << "<meta name=\"twitter:title\" content=\"Curriculum Vitae\">\n"
  seo_tags << "<meta name=\"twitter:description\" content=\"#{description_text}\">\n"

      # Additional Person JSON-LD (like in head) for stronger entity linking
  # compass and person_name already defined above
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
      # Friendly last updated (Month Year)
      display_lastmod = begin
        Date.strptime(last_modified, '%Y-%m-%d').strftime('%B %Y')
      rescue
        last_modified
      end

      self.content = <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <link href="https://fonts.googleapis.com/css2?family=Source+Sans+Pro:wght@300;400;600;700;900&display=swap" rel="stylesheet">
          <script src="https://kit.fontawesome.com/9800a0f763.js" crossorigin="anonymous"></script>
          <link rel="stylesheet" href="/assets/main.css?v={{ site.time | date: '%s' }}">
          <title>Curriculum Vitae — #{person_name}</title>
          <meta name="description" content="Academic CV for #{person_name}">
          #{seo_tags}
          #{person_jsonld_script}
          #{analytics}
          <script>(function(){try{if(window.matchMedia&&window.matchMedia('(max-width: 700px)').matches){window.location.replace('#{file_url}');}}catch(e){}})();</script>
        </head>
        <body class="embed-root">
          <div class="pdf-frame">
            <a class="pdf-download-fab" href="#{file_url}" rel="nofollow" download><i class="fas fa-download" aria-hidden="true"></i> Download PDF</a>
            #{begin
              client = site.config['adobe_pdf_client_id']
              if client && !client.to_s.strip.empty?
                <<~ADOBE
                <div id="cv-adobe-view" style="width:100%;height:100%"></div>
                <script src="https://documentcloud.adobe.com/view-sdk/main.js"></script>
                <script>
                  (function(){
                    if (window.matchMedia && window.matchMedia('(max-width: 700px)').matches) return;
                    document.addEventListener('adobe_dc_view_sdk.ready', function(){
                      try {
                        var view = new AdobeDC.View({clientId: '#{client}', divId: 'cv-adobe-view'});
                        view.previewFile({content:{location:{url:'#{file_url}'}}, metaData:{fileName:'Curriculum Vitae — #{person_name}.pdf'}},{
                          defaultViewMode: "CONTINUOUS"
                        });
                      } catch(e) {}
                    });
                  })();
                </script>
                ADOBE
              else
                "<iframe src=\"#{file_url}#page=1&zoom=page-fit\" title=\"Curriculum Vitae — #{person_name}\" loading=\"lazy\"></iframe>"
              end
            end}
          </div>
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
