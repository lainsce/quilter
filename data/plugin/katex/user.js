document.addEventListener("DOMContentLoaded", function() {
        latexify();
});

function latexify() {
    renderMathInElement(document.getElementsByClassName("markdown-body")[0], {
        delimiters: [
            { left: "\\[", right: "\\]", display: true },
            { left: "\\(", right: "\\)", display: false },
        ],
        ignoredTags: ["script", "noscript", "style", "textarea", "pre", "code"]
    });
    setupExtras();
}

function setupExtras() {
  var inlineMathArray = document.querySelectorAll("script[type='math/tex']");
  for (var i = 0; i < inlineMathArray.length; i++) {
    var inlineMath = inlineMathArray[i];
    var tex = inlineMath.innerText || inlineMath.textContent;
    var replaced = document.createElement("span");
    replaced.innerHTML = katex.renderToString(tex, { displayMode: false });
    inlineMath.parentNode.replaceChild(replaced, inlineMath);
  }
  var displayMathArray = document.querySelectorAll("script[type='math/tex; mode=display']");
  for (var i = 0; i < displayMathArray.length; i++) {
    var displayMath = displayMathArray[i];
    var tex = displayMath.innerHTML;
    var replaced = document.createElement("span");
    replaced.innerHTML = katex.renderToString(tex.replace(/%.*/g, ''), { displayMode: true });
    displayMath.parentNode.replaceChild(replaced, displayMath);
  }
}
