// sticky-ribbon-spacer.js
// Ensures: (1) first visible section ribbon overlaps under the sticky ribbon,
// (2) last visible section ribbon can scroll to top under the sticky ribbon.
function updateStickyRibbonSpacer() {
  try {
    var root = document.documentElement;
    var sticky = document.querySelector('.section-ribbon.sticky-ribbon');
    var spacer = document.getElementById('sticky-ribbon-spacer');
    var stickyHeight = sticky ? sticky.offsetHeight : 0;
    if (root) {
      root.style.setProperty('--sticky-ribbon-height', (stickyHeight || 0) + 'px');
    }

    // Reset margin on all non-sticky section ribbons
    var nonStickyRibbons = document.querySelectorAll('.section-ribbon:not(.sticky-ribbon)');
    nonStickyRibbons.forEach(function(r){ r.style.marginTop = ''; });

    function isVisible(el) {
      if (!el) return false;
      if (el.offsetParent === null) return false;
      var cs = window.getComputedStyle(el);
      return cs.display !== 'none' && cs.visibility !== 'hidden' && cs.opacity !== '0';
    }

    // Overlap: apply negative margin to the first visible section ribbon
    var firstVisible = null;
    nonStickyRibbons.forEach(function(r){ if (!firstVisible && isVisible(r)) firstVisible = r; });
    if (firstVisible && stickyHeight > 0) {
      firstVisible.style.marginTop = (-stickyHeight) + 'px';
    }

    // Spacer: compute required height so that the last visible ribbon can reach top
    if (spacer) {
      var lastVisible = null;
      nonStickyRibbons.forEach(function(r){ if (isVisible(r)) lastVisible = r; });
      if (lastVisible) {
        var rect = lastVisible.getBoundingClientRect();
        var ribbonTop = rect.top + (window.pageYOffset || window.scrollY || 0);
        var docHeight = Math.max(
          document.body.scrollHeight, document.documentElement.scrollHeight,
          document.body.offsetHeight, document.documentElement.offsetHeight,
          document.body.clientHeight, document.documentElement.clientHeight
        );
        // We want y = ribbonTop to be scrollable to y==0 in viewport (with sticky height accounted by overlap).
        // Space needed beyond current document height:
        var needed = (ribbonTop + stickyHeight) - (docHeight - window.innerHeight);
        spacer.style.height = (needed > 0 ? needed : 0) + 'px';
      } else {
        spacer.style.height = '0px';
      }
    }
  } catch (e) {
    // Fail safe: do nothing
  }
}

// Expose globally so search/other scripts can trigger recalculation
window.updateStickyRibbonSpacer = updateStickyRibbonSpacer;

document.addEventListener('DOMContentLoaded', updateStickyRibbonSpacer);
window.addEventListener('resize', updateStickyRibbonSpacer);
window.addEventListener('load', updateStickyRibbonSpacer);
setTimeout(updateStickyRibbonSpacer, 250);
