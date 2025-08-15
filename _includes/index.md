<!-- Automated Section Rendering -->
<!-- Global sticky ribbon (appears once at the top) -->
<div class="section-ribbon sticky-ribbon">
    <div class="ribbon-nav">
        {% for nav in site.data.sections %}
            <a href="#{{ nav.id }}" class="ribbon-link inactive">
                <i class="{{ nav.icon }}" aria-hidden="true"></i>
                <span class="ribbon-label">{{ nav.label }}</span>
            </a>
            {% unless forloop.last %}<span class="ribbon-sep">|</span>{% endunless %}
        {% endfor %}
    </div>
    <div class="ribbon-search">
        <div class="search-container">
            <input type="text" id="paper-search" placeholder="Search papers..." aria-label="Search papers" inputmode="search" autocapitalize="off" autocomplete="off" autocorrect="off" spellcheck="false">
            <button id="clear-search" class="clear-btn" aria-label="Clear search" role="button" type="button" style="display: none;">×</button>
        </div>
    </div>
</div>
{% for section in site.data.sections %}
<div id="{{ section.id }}">
    <div class="section-ribbon">
        <div class="ribbon-nav">
            {% for nav in site.data.sections %}
                <a href="#{{ nav.id }}" class="ribbon-link {% if nav.id == section.id %}active{% else %}inactive{% endif %}">
                    <i class="{{ nav.icon }}" aria-hidden="true"></i>
                    <span class="ribbon-label">{{ nav.label }}</span>
                </a>
                {% unless forloop.last %}<span class="ribbon-sep">|</span>{% endunless %}
            {% endfor %}
        </div>
    </div>
    {% case section.id %}
        {% when 'working-papers' %}
            {% for paper in site.data.papers.working_papers %}
            <div class="paper-card">
            <h4 style="margin-top:0;">
                {% if paper.slug %}
                <a href="/{{ paper.slug }}/"><i class="fas fa-file-alt" aria-hidden="true"></i> {{ paper.title }}</a>
                {% else %}
                <a href="{{ paper.file }}" rel="nofollow"><i class="fas fa-file-alt" aria-hidden="true"></i> {{ paper.title }}</a>
                {% endif %}
            </h4>
            <div class="authors">
                {% if paper.authors %}with {% for author_key in paper.authors %}<a href="{{ site.data.coauthors[author_key].url }}"><span class="author-name">{{ site.data.coauthors[author_key].name }}</span></a>{% unless forloop.last %}, {% endunless %}{% endfor %}{% endif %}
            {% if paper.lastmod %}<span class="version">&mdash; Version: {{ paper.lastmod | date: "%B %Y" }}</span>{% endif %}
            </div>
                    {% if paper.status or paper.journal %}
                        <div class="status-journal">
                            {% if paper.status %}<span class="status-light">{{ paper.status }}{% if paper.status and paper.journal %}, {% endif %}</span>{% endif %}{% if paper.journal %}<span class="journal-bold">{{ paper.journal }}</span>{% endif %}
                        </div>
                    {% endif %}
            {% if paper.extra_links %}
                <div class="extra-links">
                    {%- for group in paper.extra_links -%}
                        {%- if group.note and group.note != '' -%}<span class="tag-note">{{ group.note }}:</span>{%- endif -%}
                        {%- for l in group.links -%}
                            <a class="tag-label" href="{{ l.url }}"{% assign _u = l.url | downcase %}{% if _u contains '.pdf' %} rel="nofollow"{% endif %}>{{ l.label }}</a>
                        {%- endfor -%}
                    {%- endfor -%}
                </div>
            {% endif %}
            </div>
            {% endfor %}
        {% when 'publications' %}
            {% for pub in site.data.papers.publications %}
            <div class="paper-card">
            <h4 style="margin-top:0;">
                <a href="{{ pub.url }}"><i class="fa fa-book" aria-hidden="true"></i> {{ pub.title }}</a>
            </h4>
            <div class="authors">
                {% if pub.authors %}with {% for author_key in pub.authors %}<a href="{{ site.data.coauthors[author_key].url }}"><span class="author-name">{{ site.data.coauthors[author_key].name }}</span></a>{% unless forloop.last %}, {% endunless %}{% endfor %}{% endif %}
            </div>
                {% if pub.journal or pub.details %}
                    <div class="journal-version">
                        {% if pub.journal %}<span class="journal-bold">{{ pub.journal }}</span>{% endif %}{% if pub.journal and pub.details %}, {% endif %}{% if pub.details %}<span class="version">{{ pub.details }}</span>{% endif %}
                    </div>
                {% endif %}
            {% if pub.extra_links %}
                <div class="extra-links">
                    {%- for group in pub.extra_links -%}
                        {%- if group.note and group.note != '' -%}<span class="tag-note">{{ group.note }}:</span>{%- endif -%}
                        {%- for l in group.links -%}
                            {%- assign target_url = l.url -%}
                            {%- assign label_lc = l.label | default: '' | downcase | strip -%}
                            {%- if label_lc == 'working paper version' and pub.slug -%}
                                {%- assign target_url = '/' | append: pub.slug | append: '/working-paper/' -%}
                            {%- endif -%}
                            <a class="tag-label" href="{{ target_url }}"{% assign _u = target_url | downcase %}{% if _u contains '.pdf' %} rel="nofollow"{% endif %}>{{ l.label }}</a>
                        {%- endfor -%}
                    {%- endfor -%}
                </div>
            {% endif %}
            </div>
            {% endfor %}
        {% when 'work-in-progress' %}
            {% for wip in site.data.papers.work_in_progress %}
            <div class="paper-card">
            <h4 style="margin-top:0;">
                {% if wip.file %}
                <a href="{{ wip.file }}"{% assign _wf = wip.file | downcase %}{% if _wf contains '.pdf' %} rel="nofollow"{% endif %}><i class="fa fa-pencil-alt" aria-hidden="true"></i> {{ wip.title }}</a>
                {% else %}
                <i class="fa fa-pencil-alt" aria-hidden="true"></i> {{ wip.title }}
                {% endif %}
            </h4>
            <div class="authors">
                {% if wip.authors %}with {% for author_key in wip.authors %}<a href="{{ site.data.coauthors[author_key].url }}"><span class="author-name">{{ site.data.coauthors[author_key].name }}</span></a>{% unless forloop.last %}, {% endunless %}{% endfor %}{% endif %}
            </div>
            </div>
            {% endfor %}
    {% endcase %}
</div>
{% endfor %}
<div id="sticky-ribbon-spacer"></div>