window.katexDelimiters = [
    { left: "\\[", right: "\\]", display: true },
    { left: "$", right: "$", display: false }
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
    "\\d": "\\mathop{\\mathrm d#1}",
    "\\dx": "\\d x",
    "\\dt": "\\d t",
    "\\dy": "\\d y",
    "\\dd": "\\frac{\\d{}}{\\d#1}",
    "\\dydx": "\\frac{\\d#1}{\\d#2}",
    "\\dddx": "\\dfrac{\\d}{\\d#1}",
    "\\ddydx": "\\dfrac{\\d#1}{\\d#2}",
    "\\drdt": "\\dydx\\r t",
    "\\ddrdt": "\\ddydx\\r t",
    "\\p": "\\partial#1",
    "\\pp": "\\frac{\\partial}{\\p#1}",
    "\\pzpx": "\\frac{\\p#1}{\\p#2}",
    "\\dpzpx": "\\dfrac{\\p#1}{\\p#2}",
    "\\qed": "\\htmlClass{qed}{}",
    "\\contradiction": "\\mathrel↯"
};

// if there are katex macros
Object.assign(window.katexMacros, "__KATEX_MACROS__");

// queue for render calls before katex is ready
window.katexQueue = window.katexQueue || [];

// render katex with my options, when katex is ready
window.renderMath = function (container) {
    if (typeof window.katex === "undefined") {
        window.katexQueue.push(container);
        return;
    }

    //katexSetUpCustomFonts()

    renderMathInElement(container, {
        delimiters: window.katexDelimiters,
        macros: window.katexMacros,
        trust: true
    }
    );
}

document.addEventListener(
    "DOMContentLoaded", function () {
        window.renderMath(document.body);

        while (window.katexQueue.length) {
            const container = window.katexQueue.shift();
            window.renderMath(container);
        }
    }
);

// yoinked from https://yingtongli.me/blog/2022/09/24/katex-custom-fonts.html
function katexSetUpCustomFonts() {

    // All of these are textords in math mode
    const mathTextSymbols = "0123456789/@.\"";
    for (let i = 0; i < mathTextSymbols.length; i++) {
        const ch = mathTextSymbols.charAt(i);
        katex.__defineSymbol("math", "custom", "textord", ch, ch);
    }

    // All of these are textords in text mode
    const textSymbols = "0123456789!@*()-=+\";:?/.,";
    for (let i = 0; i < textSymbols.length; i++) {
        const ch = textSymbols.charAt(i);
        katex.__defineSymbol("text", "custom", "textord", ch, ch);
    }

    // All of these are textords in text mode, and mathords in math mode
    const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    for (let i = 0; i < letters.length; i++) {
        const ch = letters.charAt(i);
        katex.__defineSymbol("math", "custom", "mathord", ch, ch);
        katex.__defineSymbol("text", "custom", "textord", ch, ch);
    }

    katex.__setFontMetrics("custom-Regular", {});
    katex.__setFontMetrics("Math-Italic", {});
    katex.__setFontMetrics("AMS-Regular", {})
}


