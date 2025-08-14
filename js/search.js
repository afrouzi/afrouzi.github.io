// Simple search functionality for academic papers
(function() {
    let papers = [];
    let searchResults = null;
    let originalContent = null;

    // Initialize search functionality
    function initSearch() {
        // Extract paper data from the DOM
        extractPaperData();
        
        // Create search interface
        createSearchInterface();
        
        // Set up event listeners
        setupEventListeners();
    }

    function extractPaperData() {
        const paperCards = document.querySelectorAll('.paper-card');
        papers = [];
        
        paperCards.forEach((card, index) => {
            // Prefer linked title; fallback to plain H4 text when no link is present (e.g., some Work in Progress items)
            const titleElement = card.querySelector('h4 a') || card.querySelector('h4');
            const authorsElement = card.querySelector('.authors');
            const statusElement = card.querySelector('.status-journal, .journal-version');
            const sectionElement = card.closest('[id]');
            
            if (titleElement) {
                papers.push({
                    index: index,
                    title: titleElement.textContent.trim(),
                    authors: authorsElement ? authorsElement.textContent.replace('with ', '').trim() : '',
                    status: statusElement ? statusElement.textContent.trim() : '',
                    section: sectionElement ? sectionElement.id : '',
                    element: card
                });
            }
        });
    }

    function createSearchInterface() {
        // Search input is now in the ribbon - no additional interface needed
        return;
    }

    function setupEventListeners() {
        const searchInput = document.getElementById('paper-search');
        const clearButton = document.getElementById('clear-search');
        const ribbonSearch = document.querySelector('.ribbon-search');
        const stickyRibbon = document.querySelector('.section-ribbon.sticky-ribbon');
        
        if (searchInput) {
            // Expand on focus
            searchInput.addEventListener('focus', function() {
                if (ribbonSearch) ribbonSearch.classList.add('open');
            });
            searchInput.addEventListener('input', handleSearch);
            searchInput.addEventListener('keyup', function(e) {
                if (e.key === 'Escape') {
                    clearSearch();
                    if (ribbonSearch) ribbonSearch.classList.remove('open');
                }
            });
        }
        
        if (ribbonSearch) {
            // Make the cap keyboard-focusable
            if (!ribbonSearch.hasAttribute('tabindex')) {
                ribbonSearch.setAttribute('tabindex', '0');
            }
            function openSearchCap() {
                ribbonSearch.classList.add('open');
                if (searchInput) {
                    searchInput.focus();
                    // Put caret at end
                    const val = searchInput.value; searchInput.value = ''; searchInput.value = val;
                }
            }
            const openHandler = function(e) {
                if (e.target !== searchInput && !e.target.closest('#paper-search') && !e.target.closest('#clear-search')) {
                    openSearchCap();
                }
            };
            ribbonSearch.addEventListener('mousedown', openHandler);
            ribbonSearch.addEventListener('click', openHandler);
            ribbonSearch.addEventListener('touchstart', function(){ openSearchCap(); }, {passive:true});
            ribbonSearch.addEventListener('keydown', function(e){
                if ((e.key === 'Enter' || e.key === ' ') && !ribbonSearch.classList.contains('open')) {
                    e.preventDefault();
                    openSearchCap();
                }
            });
            // Global shortcut: '/'
            document.addEventListener('keydown', function(e){
                const active = document.activeElement;
                const inField = active && (active.tagName === 'INPUT' || active.tagName === 'TEXTAREA' || active.isContentEditable);
                if (!inField && e.key === '/') {
                    e.preventDefault();
                    openSearchCap();
                }
            });
            // Close cap on outside click/touch
            document.addEventListener('mousedown', function(e){ if (!ribbonSearch.contains(e.target)) ribbonSearch.classList.remove('open'); });
            document.addEventListener('touchstart', function(e){ if (!ribbonSearch.contains(e.target)) ribbonSearch.classList.remove('open'); }, {passive:true});
        }

        if (clearButton) {
            clearButton.addEventListener('click', clearSearch);
        }
    }

    function handleSearch() {
        const query = document.getElementById('paper-search').value.trim().toLowerCase();
        const clearButton = document.getElementById('clear-search');
        
        if (query.length === 0) {
            clearSearch();
            return;
        }
        
        // Show clear button
        clearButton.style.display = 'block';
        
        // Filter papers
        const matches = papers.filter(paper => 
            paper.title.toLowerCase().includes(query) ||
            paper.authors.toLowerCase().includes(query) ||
            paper.status.toLowerCase().includes(query)
        );
        
        displaySearchResults(matches, query);
        // Recompute overlap / active state after visibility changes
        if (typeof updateStickyRibbonSpacer === 'function') {
            try { updateStickyRibbonSpacer(); } catch (e) {}
        } else {
            window.dispatchEvent(new Event('resize'));
        }
        if (typeof updateStickyRibbonActive === 'function') {
            try { updateStickyRibbonActive(); } catch (e) {}
        }
    }

    function displaySearchResults(matches, query) {
        // Store original content if not already stored
        if (!originalContent) {
            const sections = document.querySelectorAll('[id^="working-papers"], [id^="publications"], [id^="work-in-progress"]');
            originalContent = Array.from(sections).map(section => ({
                element: section,
                display: section.style.display || ''
            }));
        }
        
        // Remove any existing no-results message
        const existingNoResults = document.querySelector('.search-no-results');
        if (existingNoResults) {
            existingNoResults.remove();
        }
        
        if (matches.length === 0) {
            // Hide all paper cards
            document.querySelectorAll('.paper-card').forEach(function(card){ card.style.display = 'none'; });

            // Hide all sections to avoid stacked ribbons
            originalContent.forEach(item => { item.element.style.display = 'none'; });

            // Build no-results after the global sticky ribbon
            const noResultsDiv = document.createElement('div');
            noResultsDiv.className = 'search-no-results';
            noResultsDiv.innerHTML = `
                <div class="no-results-content" style="padding-top: 3em; text-align: center;">
                    <i class="fas fa-search" style="font-size: 2.5em; color: #bbb; margin-bottom: 1em;"></i>
                    <h3 style="margin-bottom: 0.5em; color: #444;">No papers match your search for <strong style="color: #0074d9;">"${query}"</strong></h3>
                    <p style="color: #999; font-size: 0.95em;">Try searching for author names, paper titles, or keywords.</p>
                </div>
            `;
            const stickyRibbon = document.querySelector('.section-ribbon.sticky-ribbon');
            if (stickyRibbon) stickyRibbon.insertAdjacentElement('afterend', noResultsDiv);
            if (typeof updateStickyRibbonSpacer === 'function') { try { updateStickyRibbonSpacer(); } catch (e) {} }
        } else {
            // Hide all papers first
            document.querySelectorAll('.paper-card').forEach(function(card){ card.style.display = 'none'; });
            
            // Show matching papers and their sections
            const sectionsToShow = new Set();
            matches.forEach(paper => {
                paper.element.style.display = 'block';
                sectionsToShow.add(paper.section);
            });
            
            // Show/hide sections based on matches
            originalContent.forEach(item => {
                const sectionId = item.element.id;
                item.element.style.display = sectionsToShow.has(sectionId) ? (item.display || 'block') : 'none';
            });
        }
    }

    function clearSearch() {
        const searchInput = document.getElementById('paper-search');
        const clearButton = document.getElementById('clear-search');
        
        // Clear input
        searchInput.value = '';
        
        // Hide clear button
        clearButton.style.display = 'none';
        
        // Remove any existing no-results message
        const existingNoResults = document.querySelector('.search-no-results');
        if (existingNoResults) {
            existingNoResults.remove();
        }
        
        // Restore original content
        if (originalContent) {
            originalContent.forEach(item => {
                item.element.style.display = item.display;
            });
            
            document.querySelectorAll('.paper-card').forEach(function(card){ card.style.display = 'block'; });
        }
        if (typeof updateStickyRibbonSpacer === 'function') { try { updateStickyRibbonSpacer(); } catch (e) {} }
        if (typeof updateStickyRibbonActive === 'function') { try { updateStickyRibbonActive(); } catch (e) {} }
    }

    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initSearch);
    } else {
        initSearch();
    }
})();