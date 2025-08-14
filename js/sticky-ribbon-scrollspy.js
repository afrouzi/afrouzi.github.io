(function() {
  'use strict';

  // Utility: get sticky ribbon height (for offset calculations)
  function getStickyHeight() {
    var sticky = document.querySelector('.section-ribbon.sticky-ribbon');
    return sticky ? sticky.offsetHeight : 0;
  }

  // Utility: find the internal (non-sticky) section ribbon inside a section
  function getInnerRibbon(sectionEl) {
    if (!sectionEl) return null;
    var ribbons = sectionEl.querySelectorAll('.section-ribbon');
    for (var i = 0; i < ribbons.length; i++) {
      if (!ribbons[i].classList.contains('sticky-ribbon')) return ribbons[i];
    }
    return null;
  }

  // Visible check (display:none or detached)
  function isVisible(el) {
    if (!el) return false;
    if (el.offsetParent === null) return false;
    var style = window.getComputedStyle(el);
    return style.visibility !== 'hidden' && style.display !== 'none';
  }

  // Compute active section by scroll position
  function makeScrollSpy() {
    var stickyNav = document.querySelector('.section-ribbon.sticky-ribbon .ribbon-nav');
    if (!stickyNav) return function(){}; // no-op

    var stickyLinks = Array.prototype.slice.call(stickyNav.querySelectorAll('a.ribbon-link[href^="#"]'));
    if (!stickyLinks.length) return function(){};

    // Map links to target sections and their ribbons
    var sections = stickyLinks.map(function(link){
      var id = link.getAttribute('href').slice(1);
      var sectionEl = document.getElementById(id);
      var ribbonEl = getInnerRibbon(sectionEl) || sectionEl; // fallback to section if ribbon missing
      return { id: id, link: link, sectionEl: sectionEl, ribbonEl: ribbonEl };
    });

    function setActive(id) {
      for (var i = 0; i < sections.length; i++) {
        var l = sections[i].link;
        var isActive = (sections[i].id === id);
        l.classList.toggle('active', isActive);
        l.classList.toggle('inactive', !isActive);
        if (isActive) {
          l.setAttribute('aria-current', 'true');
        } else {
          l.removeAttribute('aria-current');
        }
      }
    }

    var ticking = false;
    function updateActive() {
      if (ticking) return;
      ticking = true;
      window.requestAnimationFrame(function(){
        ticking = false;
        var stickyOffset = getStickyHeight();
        var scrollY = window.scrollY || window.pageYOffset || 0;
        var cursor = scrollY + stickyOffset + 2; // a tiny offset to consider a ribbon active when it touches top

        // Filter visible sections (and ribbons)
        var visible = sections.filter(function(s){ return isVisible(s.sectionEl) && isVisible(s.ribbonEl); });

        if (!visible.length) {
          // No visible sections (e.g., search no-results) -> clear active
          setActive('__none__');
          return;
        }

        // Determine the last section whose ribbon top is above/equal to cursor
        var activeId = visible[0].id; // default to first visible
        for (var i = 0; i < visible.length; i++) {
          var rect = visible[i].ribbonEl.getBoundingClientRect();
          var top = rect.top + window.pageYOffset;
          if (top <= cursor) {
            activeId = visible[i].id;
          } else {
            break;
          }
        }
        setActive(activeId);
      });
    }

    // Public function for others to request an update
    window.updateStickyRibbonActive = updateActive;

    // Initial and event-driven updates
    updateActive();
    window.addEventListener('scroll', updateActive, { passive: true });
    window.addEventListener('resize', updateActive);
    window.addEventListener('load', function(){ setTimeout(updateActive, 0); });

    // Also recompute when interacting with search (sections may hide/show)
    var searchInput = document.getElementById('paper-search');
    if (searchInput) {
      ['input','change','keyup','focus','blur'].forEach(function(evt){
        searchInput.addEventListener(evt, function(){ setTimeout(updateActive, 0); });
      });
    }

    // In case other scripts expose a visibility update function, hook into it safely
    var origUpdateSpacer = window.updateStickyRibbonSpacer;
    if (typeof origUpdateSpacer === 'function') {
      window.updateStickyRibbonSpacer = function() {
        try { origUpdateSpacer.apply(this, arguments); } finally { try { updateActive(); } catch (e) {} }
      };
    }

    return updateActive;
  }

  // Initialize on DOM ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', makeScrollSpy);
  } else {
    makeScrollSpy();
  }
})();
