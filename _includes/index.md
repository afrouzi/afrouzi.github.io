
# Working Papers
{% for paper in site.data.papers.working_papers %}
### [<i class="fas fa-file-alt" aria-hidden="true"></i> {{ paper.title }}]({{ paper.file }})
{% if paper.authors %}with {% for author_key in paper.authors %}[{{ site.data.coauthors[author_key].name }}]({{ site.data.coauthors[author_key].url }}){% unless forloop.last %}, {% endunless %}{% endfor %}{% if paper.version %} --- Version: {{ paper.version }}{% endif %}<br />{% elsif paper.version %}Version: {{ paper.version }}<br />{% endif %}
{% if paper.status %}{{ paper.status }}, {% endif %}{% if paper.journal %}<span class=journal>{{ paper.journal }}</span>{% endif %}{% if paper.extra_links %}<br />{% endif %}
{% if paper.extra_links %}
    {%- for group in paper.extra_links -%}
        {%- if group.links.size == 1 -%}
            <a href="{{ group.links[0].url }}">{{ group.note }}</a>{% unless forloop.last %}; {% endunless %}
        {%- else -%}
            {{ group.note }} ({%- for l in group.links -%}<a href="{{ l.url }}">{{ l.label }}</a>{% unless forloop.last %}, {% endunless %}{%- endfor -%}){% unless forloop.last %}; {% endunless %}
        {%- endif -%}
    {%- endfor -%}
{% endif %}
{% endfor %}



# Publications
{% for pub in site.data.papers.publications %}
### [<i class="fa fa-book" aria-hidden="true"></i> {{ pub.title }}]({{ pub.url }})
{% if pub.authors %}with {% for author_key in pub.authors %}[{{ site.data.coauthors[author_key].name }}]({{ site.data.coauthors[author_key].url }}){% unless forloop.last %}, {% endunless %}{% endfor %}{% if pub.journal %}<br /><span class=journal>{{ pub.journal }}</span>{% endif %}{% if pub.details %} {{ pub.details }}{% endif %}<br />{% else %}{% if pub.journal %}<span class=journal>{{ pub.journal }}</span>{% endif %}{% if pub.details %} {{ pub.details }}{% endif %}{% endif %}
{% endfor %}



# Work in Progress
{% for wip in site.data.papers.work_in_progress %}
### {% if wip.file %}[<i class="fa fa-pencil-alt" aria-hidden="true"></i> {{ wip.title }}]({{ wip.file }}){% else %}<i class="fa fa-pencil-alt" aria-hidden="true"></i> {{ wip.title }}{% endif %}
{% if wip.authors %}with {% for author_key in wip.authors %}[{{ site.data.coauthors[author_key].name }}]({{ site.data.coauthors[author_key].url }}){% unless forloop.last %}, {% endunless %}{% endfor %}{% endif %}
{% endfor %}