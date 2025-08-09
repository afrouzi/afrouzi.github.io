
// Smooth scroll for sticky ribbon navigation (plain JS, no Zepto/jQuery required)
(function() {
  // Ease-out cubic for fast-then-slow scroll
  function easeOutCubic(t) {
    return 1 - Math.pow(1 - t, 3);
  }
  function smoothScrollTo(targetY, duration) {
    var startY = window.scrollY || window.pageYOffset;
    var diff = targetY - startY;
    var startTime = null;
    function step(timestamp) {
      if (!startTime) startTime = timestamp;
      var time = timestamp - startTime;
      var percent = Math.min(time / duration, 1);
      var eased = easeOutCubic(percent);
      window.scrollTo(0, startY + diff * eased);
      if (percent < 1) {
        window.requestAnimationFrame(step);
      }
    }
    window.requestAnimationFrame(step);
  }

  function getStickyOffset() {
    var sticky = document.querySelector('.sticky-ribbon');
    if (!sticky) return 0;
    return sticky.offsetHeight;
  }

  document.addEventListener('click', function(e) {
    var link = e.target.closest('.ribbon-link');
    if (!link) return;
    var href = link.getAttribute('href');
    if (href && href.startsWith('#')) {
      var target = document.getElementById(href.slice(1));
      if (target) {
        e.preventDefault();
        var sticky = document.querySelector('.sticky-ribbon');
        var stickyHeight = sticky ? sticky.offsetHeight : 0;
        // Find the section ribbon inside the target section, but skip sticky-ribbon
        var sectionRibbon = null;
        var ribbons = target.querySelectorAll('.section-ribbon');
        for (var i = 0; i < ribbons.length; i++) {
          if (!ribbons[i].classList.contains('sticky-ribbon')) {
            sectionRibbon = ribbons[i];
            break;
          }
        }
        var scrollToY;
        if (sectionRibbon) {
          // Always scroll so the section ribbon lands at the very top of the viewport
          var sectionRibbonRect = sectionRibbon.getBoundingClientRect();
          var sectionRibbonY = sectionRibbonRect.top + window.pageYOffset;
          scrollToY = sectionRibbonY;
        } else {
          // Fallback: scroll to the section top
          var targetRect = target.getBoundingClientRect();
          scrollToY = targetRect.top + window.pageYOffset;
        }
        // Always scroll to the calculated position (fixes browser jump on backward transitions)
        setTimeout(function() {
          var currentY = window.scrollY || window.pageYOffset;
          if (Math.abs(currentY - scrollToY) > 2) {
            smoothScrollTo(scrollToY, 650);
          }
        }, 0);
        // Optionally update URL hash without jumping
        if (history.pushState) {
          history.pushState(null, null, href);
        } else {
          window.location.hash = href;
        }
      }
    }
  }, false);
})();
