function embedDesmos(divId, state, bounds) {
  const elt = document.getElementById(divId);
  const calc = Desmos.GraphingCalculator(elt, {
    keypad: false,
    expressions: false,
    settingsMenu: false,
    zoomButtons: false,
    lockViewport: true,
    pointsOfInterest: false
  });
  calc.setState(state);
  if(bounds) calc.setMathBounds(bounds);
  return calc;
}