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
})();
