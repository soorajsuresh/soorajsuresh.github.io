window.katexDelimiters = [
    { left: "\\[", right: "\\]", display: true },
    { left: "$",  right: "$",  display: false }
];

window.katexMacros = {
    "\\phi": "\\varphi",
    "\\parens": "\\left(\\,#1\\,\\right)",
    "\\bracks": "\\left[\\,#1\\,\\right]",
    "\\set": "\\left\\{\\,#1\\,\\right\\}",
    "\\build": "\\left\\{#1\\;\\middle|\\;#2\\right\\}",
    "\\abs": "\\left\\lvert\\,#1\\,\\right\\rvert",
    "\\point": "\\left(\\,#1,\\,#2,\\,#3\\,\\right)",
    "\\inner": "\\left\\langle\\,#1\\,\\right\\rangle",
    "\\vector": "\\inner{#1,\\,#2,\\,#3}",
    "\\asin": "\\sin^{-1}",
    "\\acos": "\\cos^{-1}",
    "\\atan": "\\tan^{-1}",
    "\\asinh": "\\sinh^{-1}",
    "\\acosh": "\\cosh^{-1}",
    "\\atanh": "\\tanh^{-1}",
    "\\arsinh": "\\mathop{\\operatorname{arsinh}}",
    "\\sech": "\\mathop{\\operatorname{sech}}",
    "\\erf": "\\mathop{\\operatorname{erf}}",
    "\\e": "\\mathrm e",
    "\\d" : "\\mathop{\\mathrm d#1}",
    "\\dx" : "\\d x",
    "\\dt" : "\\d t",
    "\\dy" : "\\d y",
    "\\dd" : "\\frac{\\d{}}{\\d#1}",
    "\\dydx" : "\\frac{\\d#1}{\\d#2}",
    "\\dddx" : "\\dfrac{\\d}{\\d#1}",
    "\\ddydx" : "\\dfrac{\\d#1}{\\d#2}",
    "\\drdt" : "\\dydx\\r t",
    "\\ddrdt" : "\\ddydx\\r t",
    "\\p" : "\\partial#1",
    "\\pp" : "\\frac{\\partial}{\\p#1}",
    "\\pzpx" : "\\frac{\\p#1}{\\p#2}",
    "\\dpzpx" : "\\dfrac{\\p#1}{\\p#2}",
    "\\qed" : "\\htmlClass{qed}{}",
    "\\contradiction" : "\\mathrel↯"
};    

// queue for render calls before katex is ready
window.katexQueue = window.katexQueue || [];

// render katex with my options, when katex is ready
window.renderMath = function(container) {
    if (typeof window.katex === "undefined") {
        window.katexQueue.push(container);
        return;
    }
    renderMathInElement(container, {
            delimiters: window.katexDelimiters,
            macros: window.katexMacros,
            trust: true
        }
    );
}

document.addEventListener(
    "DOMContentLoaded", function() {
        window.renderMath(document.body);

        while (window.katexQueue.length) {
            const container = window.katexQueue.shift();
            window.renderMath(container);
        }
    }
);
