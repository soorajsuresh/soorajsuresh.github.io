fetch("log.txt").then(response => response.text()).then(text => console.log(text));

let [timerButton, msecDisplay, secDisplay, minDisplay, hrDisplay] = [
    document.getElementById("timerButton"),
    document.getElementById("msecDisplay"),
    document.getElementById("secDisplay"),
    document.getElementById("minDisplay"),
    document.getElementById("hrDisplay")
];
let timing = false;
let [msecs,secs,mins,hrs] = [0,0,0,0];
time();

timerButton.addEventListener('click', () => {
    if (!timing) {
        timing = true;
        timerButton.textContent = "Pause";
        document.getElementById("currentNotes").disabled = true;
    } else {
        timing = false;
        timerButton.textContent = "Continue";
        document.getElementById("currentNotes").disabled = false;
    }
});

function time() {
    if (timing) {
        msecs += 10;
        if (msecs >= 1000) {
            msecs -= 1000;
            secs++;
            if (secs >= 60) {
                secs -= 60;
                mins++;
                if (mins >= 60) {
                    mins -= 60;
                    hrs++;
                }
            }
        }
        [hrDisplay.textContent,minDisplay.textContent,secDisplay.textContent,msecDisplay.textContent] = [
            hrs < 10 ? "0" + hrs : hrs, 
            mins < 10 ? "0" + mins : mins,
            secs < 10 ? "0" + secs : secs, 
            msecs < 10 ? "00" + msecs : msecs < 100 ? "0" + msecs : msecs];
    }
    setTimeout(time, 10);
}