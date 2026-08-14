// Site search dialog (markup in templates/partials/search.html).
// Two result tiers: section headings from window.searchHeadings, matched by
// substring and linking straight to the anchor, then full-text page matches
// from Zola's elasticlunr index, fetched on first use.
(function () {
  var dialog = document.getElementById("search-dialog");
  var input = document.getElementById("search-input");
  var results = document.getElementById("search-results");
  var MAX_HEADINGS = 8;
  var MAX_PAGES = 5;

  var indexPromise;
  function loadIndex() {
    if (!indexPromise) {
      indexPromise = fetch("/search_index.en.json")
        .then(function (r) { return r.json(); })
        .then(function (data) { return elasticlunr.Index.load(data); });
    }
    return indexPromise;
  }

  function openDialog() {
    dialog.showModal();
    input.select();
    loadIndex();
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

  // Taken from Zola's own search.js, in turn taken from mdbook. Assign a
  // weight to each word (search terms, stemmer aware: 40; sentence starts: 8;
  // rest: 2), slide a 30-word window over the document, and keep the window
  // with the largest total. Terms are wrapped in <b>.
  function makeTeaser(body, terms) {
    var TERM_WEIGHT = 40;
    var NORMAL_WORD_WEIGHT = 2;
    var FIRST_WORD_WEIGHT = 8;
    var TEASER_MAX_WORDS = 30;

    var stemmedTerms = terms.map(function (w) {
      return elasticlunr.stemmer(w.toLowerCase());
    });
    var termFound = false;
    var index = 0;
    var weighted = []; // contains elements of ["word", weight, index_in_document]

    // split in sentences, then words
    var sentences = body.toLowerCase().split(". ");

    for (var i in sentences) {
      var words = sentences[i].split(" ");
      var value = FIRST_WORD_WEIGHT;

      for (var j in words) {
        var word = words[j];

        if (word.length > 0) {
          for (var k in stemmedTerms) {
            if (elasticlunr.stemmer(word).startsWith(stemmedTerms[k])) {
              value = TERM_WEIGHT;
              termFound = true;
            }
          }
          weighted.push([word, value, index]);
          value = NORMAL_WORD_WEIGHT;
        }

        index += word.length;
        index += 1; // ' ' or '.' if last word in sentence
      }

      index += 1; // because we split at a two-char boundary '. '
    }

    if (weighted.length === 0) {
      return escapeHtml(body);
    }

    var windowWeights = [];
    var windowSize = Math.min(weighted.length, TEASER_MAX_WORDS);
    var curSum = 0;
    for (var i = 0; i < windowSize; i++) {
      curSum += weighted[i][1];
    }
    windowWeights.push(curSum);

    for (var i = 0; i < weighted.length - windowSize; i++) {
      curSum -= weighted[i][1];
      curSum += weighted[i + windowSize][1];
      windowWeights.push(curSum);
    }

    // If we didn't find the term, just pick the first window
    var maxSumIndex = 0;
    if (termFound) {
      var maxFound = 0;
      // backwards
      for (var i = windowWeights.length - 1; i >= 0; i--) {
        if (windowWeights[i] > maxFound) {
          maxFound = windowWeights[i];
          maxSumIndex = i;
        }
      }
    }

    var teaser = [];
    var startIndex = weighted[maxSumIndex][2];
    for (var i = maxSumIndex; i < maxSumIndex + windowSize; i++) {
      var word = weighted[i];
      if (startIndex < word[2]) {
        // missing text from index to start of `word`
        teaser.push(escapeHtml(body.substring(startIndex, word[2])));
        startIndex = word[2];
      }

      if (word[1] === TERM_WEIGHT) {
        teaser.push("<b>");
      }
      startIndex = word[2] + word[0].length;
      teaser.push(escapeHtml(body.substring(word[2], startIndex)));

      if (word[1] === TERM_WEIGHT) {
        teaser.push("</b>");
      }
    }
    teaser.push("…");
    return teaser.join("");
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
    var pages = [];
    try {
      pages = (await loadIndex()).search(term, {
        bool: "AND",
        expand: true,
        fields: { title: { boost: 2 }, body: { boost: 1 } },
      }).slice(0, MAX_PAGES);
    } catch (e) {
      console.error("search index unavailable:", e);
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
    if (pages.length > 0) {
      addGroupLabel("Pages");
      pages.forEach(function (item) {
        addResult(item.ref, "Page", escapeHtml(item.doc.title),
          makeTeaser(item.doc.body, term.split(" ")));
      });
    }
    if (headings.length === 0 && pages.length === 0) {
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
