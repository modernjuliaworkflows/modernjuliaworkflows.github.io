// Site search dialog (markup in templates/partials/search.html).
// Two result tiers: section headings from window.searchHeadings, matched by
// substring and linking straight to the anchor, then full-text matches from
// the Pagefind bundle (built into public/pagefind/ by `pagefind --site public`
// after `zola build`), whose sub-results link to the anchor of the heading
// the match sits under.
(function () {
  var dialog = document.getElementById("search-dialog");
  var input = document.getElementById("search-input");
  var results = document.getElementById("search-results");
  var MAX_HEADINGS = 8;
  var MAX_PAGES = 5; // full-text page hits to load
  var MAX_SUBRESULTS = 3; // sections shown per page hit

  var pagefindPromise;
  function loadPagefind() {
    if (!pagefindPromise) {
      // The bundle only exists in a full build; under `zola serve` the import
      // rejects and runSearch degrades to the headings tier.
      pagefindPromise = import("/pagefind/pagefind.js").then(function (pf) {
        pf.init();
        return pf;
      });
      pagefindPromise.catch(function () {}); // silence the warmup rejection
    }
    return pagefindPromise;
  }

  function openDialog() {
    dialog.showModal();
    input.select();
    loadPagefind();
  }

  document.getElementById("search-open").addEventListener("click", openDialog);
  document.addEventListener("keydown", function (e) {
    if (dialog.open) return;
    var typing = /^(INPUT|TEXTAREA|SELECT)$/.test(document.activeElement.tagName);
    if ((e.key === "/" && !typing) || (e.key === "k" && (e.metaKey || e.ctrlKey))) {
      e.preventDefault();
      openDialog();
    }
  });
  // Close on backdrop click, and on result click (anchors on the current page
  // don't trigger a page load, so the dialog would stay open).
  dialog.addEventListener("click", function (e) {
    if (e.target === dialog || e.target.closest("a")) dialog.close();
  });
  // Escape steps out in two stages: with a query it clears the input, without
  // one it closes the dialog. Done by hand because the native behavior (clear
  // on type="search", cancel on the dialog) is inconsistent across browsers.
  dialog.addEventListener("keydown", function (e) {
    if (e.key !== "Escape") return;
    e.preventDefault();
    if (input.value !== "") {
      input.value = "";
      runSearch();
    } else {
      dialog.close();
    }
  });

  function escapeHtml(s) {
    return s.replace(/[&<>"]/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c];
    });
  }

  // Heading permalinks are absolute (Zola's base_url), Pagefind URLs are
  // root-relative; normalize both for cross-tier dedup.
  function urlKey(url) {
    var u = new URL(url, window.location.origin);
    return u.pathname + u.hash;
  }

  // Substring match over the heading index; prefix and word-start matches rank
  // before mid-word ones.
  function matchHeadings(term) {
    var q = term.toLowerCase();
    var matches = [];
    window.searchHeadings.forEach(function (h) {
      var i = h.title.toLowerCase().indexOf(q);
      if (i === -1) return;
      var rank = i === 0 ? 0 : (h.title[i - 1] === " " ? 1 : 2);
      matches.push({ heading: h, at: i, rank: rank });
    });
    matches.sort(function (a, b) { return a.rank - b.rank; });
    return matches.slice(0, MAX_HEADINGS);
  }

  function addGroupLabel(text) {
    var label = document.createElement("div");
    label.className = "search-group-label";
    label.textContent = text;
    results.appendChild(label);
  }

  function addResult(url, crumb, titleHtml, teaserHtml) {
    var a = document.createElement("a");
    a.className = "search-result";
    a.href = url;
    var title = document.createElement("div");
    title.className = "search-result-title";
    title.innerHTML =
      '<span class="search-crumb">' + escapeHtml(crumb) + " ▸ </span>" + titleHtml;
    a.appendChild(title);
    if (teaserHtml) {
      var teaser = document.createElement("div");
      teaser.className = "search-teaser";
      teaser.innerHTML = teaserHtml;
      a.appendChild(teaser);
    }
    results.appendChild(a);
  }

  var lastTerm = "";
  async function runSearch() {
    var term = input.value.trim();
    if (term === lastTerm) return;
    lastTerm = term;
    results.replaceChildren();
    if (term === "") return;

    var headings = matchHeadings(term);
    var seen = {};
    headings.forEach(function (m) { seen[urlKey(m.heading.url)] = true; });

    var matches = [];
    try {
      var pagefind = await loadPagefind();
      var search = await pagefind.search(term);
      var pages = await Promise.all(
        search.results.slice(0, MAX_PAGES).map(function (r) { return r.data(); })
      );
      pages.forEach(function (page) {
        page.sub_results.slice(0, MAX_SUBRESULTS).forEach(function (sub) {
          if (seen[urlKey(sub.url)]) return; // already shown as a heading match
          seen[urlKey(sub.url)] = true;
          matches.push({ page: page.meta.title, sub: sub });
        });
      });
    } catch (e) {
      console.error("full-text search unavailable (the index is built by `pagefind --site public`):", e);
    }
    if (input.value.trim() !== term) return; // stale response

    if (headings.length > 0) {
      addGroupLabel("Sections");
      headings.forEach(function (m) {
        var t = m.heading.title;
        var titleHtml =
          escapeHtml(t.substring(0, m.at)) +
          "<b>" + escapeHtml(t.substring(m.at, m.at + term.length)) + "</b>" +
          escapeHtml(t.substring(m.at + term.length));
        addResult(m.heading.url, m.heading.page, titleHtml);
      });
    }
    if (matches.length > 0) {
      addGroupLabel("Content");
      matches.forEach(function (m) {
        // Pagefind escapes the excerpt itself and marks hits with <mark>.
        addResult(m.sub.url, m.page, escapeHtml(m.sub.title), m.sub.excerpt);
      });
    }
    if (headings.length === 0 && matches.length === 0) {
      var empty = document.createElement("div");
      empty.className = "search-empty";
      empty.textContent = "No results for “" + term + "”";
      results.appendChild(empty);
    }
  }

  var debounceTimer;
  input.addEventListener("input", function () {
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(runSearch, 120);
  });

  // Keyboard selection: arrows move, Enter follows (first result by default).
  input.addEventListener("keydown", function (e) {
    var items = results.querySelectorAll("a.search-result");
    if (items.length === 0) return;
    var i = Array.prototype.indexOf.call(items, results.querySelector(".selected"));
    if (e.key === "Enter") {
      items[Math.max(i, 0)].click();
    } else if (e.key === "ArrowDown" || e.key === "ArrowUp") {
      if (i === -1 && e.key === "ArrowUp") i = 0; // wrap to the last item
      i = (i + (e.key === "ArrowDown" ? 1 : -1) + items.length) % items.length;
      items.forEach(function (el) { el.classList.remove("selected"); });
      items[i].classList.add("selected");
      items[i].scrollIntoView({ block: "nearest" });
    } else {
      return;
    }
    e.preventDefault();
  });
})();
