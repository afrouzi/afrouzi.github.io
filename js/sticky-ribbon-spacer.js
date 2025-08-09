// sticky-ribbon-spacer.js
// Dynamically adds enough space after the last section for the sticky ribbon to scroll to the top
function updateStickyRibbonSpacer() {
  var ribbons = document.querySelectorAll('.section-ribbon.sticky-ribbon');
  var spacer = document.getElementById('sticky-ribbon-spacer');
  if (ribbons.length && spacer) {
    var lastRibbon = ribbons[ribbons.length - 1];
    var mainContent = document.querySelector('.main-content');
    var ribbonRect = lastRibbon.getBoundingClientRect();
    var mainContentRect = mainContent ? mainContent.getBoundingClientRect() : null;
    // Calculate the distance from the top of the last ribbon to the bottom of the viewport
    var spaceBelow = 0;
    if (mainContentRect) {
      // The distance from the top of the last ribbon to the bottom of the main content
      spaceBelow = mainContentRect.bottom - ribbonRect.top;
    }
    // The needed space is the viewport height minus the spaceBelow
    var needed = window.innerHeight - spaceBelow;
    if (needed > 0) {
      spacer.style.height = needed + "px";
    } else {
      spacer.style.height = "0px";
    }
  }
}

document.addEventListener("DOMContentLoaded", updateStickyRibbonSpacer);
window.addEventListener("resize", updateStickyRibbonSpacer);
