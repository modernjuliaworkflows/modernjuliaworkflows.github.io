// Theme toggle and mobile drawer (markup in templates/base.html and
// templates/partials/sidebar.html). The saved theme is applied before
// first paint by the inline script in base.html's <head>; this file
// only handles interaction.
(function () {
  // Point the generated giallo stylesheets at the active theme. With no
  // explicit choice they follow the system preference on their own.
  function syncHighlight() {
    var t = document.documentElement.dataset.theme || "";
    document.getElementById("hl-light").media =
      t ? (t === "light" ? "all" : "not all") : "(prefers-color-scheme: light)";
    document.getElementById("hl-dark").media =
      t ? (t === "dark" ? "all" : "not all") : "(prefers-color-scheme: dark)";
  }

  document.getElementById("theme-toggle").addEventListener("click", function () {
    var explicit = document.documentElement.dataset.theme;
    var effective = explicit ||
      (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");
    var next = effective === "dark" ? "light" : "dark";
    document.documentElement.dataset.theme = next;
    try {
      localStorage.setItem("theme", next);
    } catch (e) {} // private browsing: the choice just won't persist
    syncHighlight();
  });

  // Mobile drawer: the sidebar slides in over a backdrop.
  var body = document.body;
  function closeDrawer() {
    body.classList.remove("sidebar-open");
  }
  document.getElementById("menu-open").addEventListener("click", function () {
    body.classList.toggle("sidebar-open");
  });
  document.getElementById("sidebar-backdrop").addEventListener("click", closeDrawer);
  // Close on any nav click: same-page anchors don't trigger a page load,
  // so the drawer would otherwise stay open over the scrolled content.
  document.querySelector(".sidebar").addEventListener("click", function (e) {
    if (e.target.closest("a")) closeDrawer();
  });
  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape" && body.classList.contains("sidebar-open")) closeDrawer();
  });

  // Scrollspy: mark the section currently being read in the sidebar list.
  // Current is the last heading above the reading line — the heading's own
  // scroll-margin-top plus some slack, so following a section link also
  // highlights the section it jumps to.
  var spyLinks = [];
  var spyHeadings = [];
  document.querySelectorAll(".menu-list-child-list.active .menu-list-link")
    .forEach(function (link) {
      var heading = document.getElementById(decodeURIComponent(link.hash.slice(1)));
      if (heading) {
        spyLinks.push(link);
        spyHeadings.push(heading);
      }
    });
  if (spyHeadings.length) {
    var currentLink = null;
    var updateSpy = function () {
      var line = parseFloat(getComputedStyle(spyHeadings[0]).scrollMarginTop) + 8;
      var current = null;
      for (var i = 0; i < spyHeadings.length; i++) {
        if (spyHeadings[i].getBoundingClientRect().top <= line) current = spyLinks[i];
      }
      // A short final section may never reach the reading line; count it
      // once the page is scrolled to the bottom.
      if (window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 2) {
        current = spyLinks[spyLinks.length - 1];
      }
      if (current !== currentLink) {
        if (currentLink) currentLink.classList.remove("current");
        if (current) current.classList.add("current");
        currentLink = current;
      }
    };
    var spyPending = false;
    window.addEventListener("scroll", function () {
      if (spyPending) return;
      spyPending = true;
      requestAnimationFrame(function () {
        spyPending = false;
        updateSpy();
      });
    }, { passive: true });
    window.addEventListener("resize", updateSpy);
    updateSpy();
  }
})();
