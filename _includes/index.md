

<div id="working-papers">
    <div class="section-ribbon sticky-ribbon">
            <a href="#working-papers" class="ribbon-link active"> Working Papers </a>
            <span class="ribbon-sep">|</span>
            <a href="#publications" class="ribbon-link inactive"> Publications </a>
            <span class="ribbon-sep">|</span>
            <a href="#work-in-progress" class="ribbon-link inactive"> Work in Progress </a>
    </div>
    {% for paper in site.data.papers.working_papers %}
    <div class="paper-card">
    <h4 style="margin-top:0;">
        <a href="{{ paper.file }}"><i class="fas fa-file-alt" aria-hidden="true"></i> {{ paper.title }}</a>
    </h4>
    <div class="authors">
        {% if paper.authors %}with {% for author_key in paper.authors %}<a href="{{ site.data.coauthors[author_key].url }}">{{ site.data.coauthors[author_key].name }}</a>{% unless forloop.last %}, {% endunless %}{% endfor %}{% endif %}
    {% if paper.version %}<span class="version">&mdash; Version: {{ paper.version }}</span>{% endif %}
    </div>
            {% if paper.status or paper.journal %}
                <div class="status-journal">
                    {% if paper.status %}<span class="status-light">{{ paper.status }}</span>{% endif %}{% if paper.status and paper.journal %}, {% endif %}{% if paper.journal %}<span class="journal-bold">{{ paper.journal }}</span>{% endif %}
                </div>
            {% endif %}
    {% if paper.extra_links %}
        <div class="extra-links">
            {%- for group in paper.extra_links -%}
                {%- if group.links.size == 1 -%}
                    <a href="{{ group.links[0].url }}">{{ group.note }}</a>{% unless forloop.last %}; {% endunless %}
                {%- else -%}
                    {{ group.note }} ({%- for l in group.links -%}<a href="{{ l.url }}">{{ l.label }}</a>{% unless forloop.last %}, {% endunless %}{%- endfor -%}){% unless forloop.last %}; {% endunless %}
                {%- endif -%}
            {%- endfor -%}
        </div>
    {% endif %}

    </div>
    {% endfor %}
</div>




<div id="publications">
    <div class="section-ribbon sticky-ribbon">
            <a href="#working-papers" class="ribbon-link inactive">Working Papers</a>
            <span class="ribbon-sep">|</span>
            <a href="#publications" class="ribbon-link active">Publications</a>
            <span class="ribbon-sep">|</span>
            <a href="#work-in-progress" class="ribbon-link inactive">Work in Progress</a>
    </div>
    {% for pub in site.data.papers.publications %}
    <div class="paper-card">
    <h4 style="margin-top:0;">
        <a href="{{ pub.url }}"><i class="fa fa-book" aria-hidden="true"></i> {{ pub.title }}</a>
    </h4>
    <div class="authors">
        {% if pub.authors %}with {% for author_key in pub.authors %}<a href="{{ site.data.coauthors[author_key].url }}">{{ site.data.coauthors[author_key].name }}</a>{% unless forloop.last %}, {% endunless %}{% endfor %}{% endif %}
    </div>
        {% if pub.journal or pub.details %}
            <div class="journal-version">
                {% if pub.journal %}<span class="journal">{{ pub.journal }}</span>{% endif %}{% if pub.journal and pub.details %}, {% endif %}{% if pub.details %}<span class="version">{{ pub.details }}</span>{% endif %}
            </div>
        {% endif %}

    </div>
    {% endfor %}
</div>




<div id="work-in-progress">
    <div class="section-ribbon sticky-ribbon">
            <a href="#working-papers" class="ribbon-link inactive">Working Papers</a>
            <span class="ribbon-sep">|</span>
            <a href="#publications" class="ribbon-link inactive">Publications</a>
            <span class="ribbon-sep">|</span>
            <a href="#work-in-progress" class="ribbon-link active">Work in Progress</a>
    </div>
    {% for wip in site.data.papers.work_in_progress %}
    <div class="paper-card">
    <h4 style="margin-top:0;">
        {% if wip.file %}<a href="{{ wip.file }}"><i class="fa fa-pencil-alt" aria-hidden="true"></i> {{ wip.title }}</a>{% else %}<i class="fa fa-pencil-alt" aria-hidden="true"></i> {{ wip.title }}{% endif %}
    </h4>
    <div class="authors">
        {% if wip.authors %}with {% for author_key in wip.authors %}<a href="{{ site.data.coauthors[author_key].url }}">{{ site.data.coauthors[author_key].name }}</a>{% unless forloop.last %}, {% endunless %}{% endfor %}{% endif %}
    </div>

    </div>
    {% endfor %}
</div>