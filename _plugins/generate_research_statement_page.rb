# frozen_string_literal: true

require 'json'
require 'date'

module Jekyll
  class ResearchStatementPage < Page
    def initialize(site, base, dir, pdf_path, last_modified)
      @site = site
      @base = base
      @dir  = dir
      @name = 'index.html'

      self.process(@name)
      self.data = { 'layout' => nil, 'title' => 'Research Statement', 'file' => pdf_path, 'last_updated' => last_modified }

      site_url = site.config['url'] || ''
      baseurl = site.config['baseurl'] || ''
      slug_url = site_url.chomp('/') + baseurl + '/research-statement/'
      file_url = '/research_statement.pdf'
      full_pdf = site_url.chomp('/') + file_url
      homepage_url = site_url.chomp('/') + baseurl + '/'

  # SEO / social tags unified
  description_text = 'Research Statement — Hassan Afrouzi'
  site_title = site.config['title']
  head_tags = String.new
  head_tags << "<link rel=\"canonical\" href=\"#{slug_url}\">\n"
  head_tags << "<link rel=\"alternate\" type=\"application/pdf\" href=\"#{full_pdf}\">\n"
  head_tags << "<meta name=\"description\" content=\"#{description_text}\">\n"
  head_tags << "<meta name=\"author\" content=\"Hassan Afrouzi\">\n"
  head_tags << "<meta property=\"og:title\" content=\"Research Statement\">\n"
  head_tags << "<meta property=\"og:description\" content=\"#{description_text}\">\n"
  head_tags << "<meta property=\"og:type\" content=\"article\">\n"
  head_tags << "<meta property=\"og:url\" content=\"#{slug_url}\">\n"
  head_tags << "<meta property=\"og:site_name\" content=\"#{site_title}\">\n" if site_title
  head_tags << "<meta name=\"twitter:card\" content=\"summary\">\n"
  head_tags << "<meta name=\"twitter:title\" content=\"Research Statement\">\n"
  head_tags << "<meta name=\"twitter:description\" content=\"#{description_text}\">\n"

      # JSON-LD as a simple CreativeWork
      jsonld = {
        "@context" => "https://schema.org",
        "@type" => "CreativeWork",
        "name" => "Research Statement",
        "url" => slug_url,
        "isAccessibleForFree" => true,
        "mainEntityOfPage" => homepage_url,
        "encoding" => {
          "@type" => "MediaObject",
          "contentUrl" => full_pdf,
          "fileFormat" => "application/pdf"
        }
      }
      if last_modified && last_modified =~ /\A\d{4}-\d{2}-\d{2}\z/
        jsonld["dateModified"] = last_modified
      end
      jsonld_script = "<script type=\"application/ld+json\">#{JSON.generate(jsonld)}</script>\n"

      analytics = ''
      analytics = '{% include analytics.html %}' if site.config.dig('compass', 'include_analytics')

      viewer_src = "/assets/pdfjs/viewer.html?file=#{URI.encode_www_form_component(file_url)}#pagemode=none"

      self.content = <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
          <title>Research Statement</title>
          #{head_tags}
          #{jsonld_script}
          #{analytics}
          <style>html,body{height:100%;margin:0;background:#f6faef} .viewer-frame{position:fixed;inset:0;border:0;width:100%;height:100%}</style>
        </head>
        <body>
          <iframe class="viewer-frame" src="#{viewer_src}" title="Research Statement" allow="fullscreen"></iframe>
          <!-- Pinch zoom handled in embedded viewer -->
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
    end
  end

  class GenerateResearchStatementPage < Generator
    safe true
    priority :low

    def generate(site)
      pdf_rel = '_files/research_statement.pdf'
      abs_pdf = File.join(site.source, pdf_rel)
      if File.exist?(abs_pdf)
        last_modified = File.mtime(abs_pdf).strftime('%Y-%m-%d')
      else
        last_modified = nil
      end
      site.pages << ResearchStatementPage.new(site, site.source, 'research-statement', pdf_rel, last_modified)
    end
  end
end
