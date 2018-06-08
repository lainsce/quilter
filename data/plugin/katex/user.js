document.addEventListener("DOMContentLoaded", function() {
        latexify();
});

function latexify() {
    setupExtras();
    renderMathInElement(document.getElementsByClassName("markdown-body")[0], {
        delimiters: [
            { left: "\\[", right: "\\]", display: true },
            { left: "\\(", right: "\\)", display: false },
        ],
        ignoredTags: ["script", "noscript", "style", "textarea", "pre", "code"]
    });
    
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
  for (var j = 0; j < displayMathArray.length; j++) {
    var displayMath = displayMathArray[j];
    var texj = displayMath.innerHTML;
    var replacedj = document.createElement("span");
    replacedj.innerHTML = katex.renderToString(texj.replace(/%.*/g, ''), { displayMode: true });
    displayMath.parentNode.replaceChild(replacedj, displayMath);
  }
}
