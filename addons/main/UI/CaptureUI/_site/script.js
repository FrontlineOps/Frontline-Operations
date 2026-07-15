//=============================================================================
// FLO Capture UI - JavaScript Controller
//=============================================================================

let captureUI = null;

class CaptureUI {
    constructor() {
        this.container = document.getElementById('capture-container');
        this.redBar = document.getElementById('red-bar');
        this.blueBar = document.getElementById('blue-bar');
        this.separator = document.getElementById('separator');
        this.barGlow = document.getElementById('bar-glow');
        this.objectiveLabel = document.getElementById('objective-label');
        this.statusText = document.getElementById('status-text');
        
        this.currentRatio = 0.5;
        this.targetRatio = 0.5;
        this.animationFrame = null;
        this.isVisible = false;
    }

    show(objectiveName) {
        this.objectiveLabel.textContent = objectiveName || 'OBJECTIVE';
        this.container.classList.remove('hidden');
        this.isVisible = true;
        this.startAnimation();
    }

    hide() {
        this.container.classList.add('hidden');
        this.isVisible = false;
        if (this.animationFrame) {
            cancelAnimationFrame(this.animationFrame);
            this.animationFrame = null;
        }
    }

    applyState(snapshot) {
        const friendlyRatio = Math.max(0, Math.min(1, snapshot.ratio));
        const friendlyIsWest = snapshot.friendlySide === 'WEST';
        const friendlyClass = friendlyIsWest ? 'captured-blue' : 'captured-red';
        const enemyClass = friendlyIsWest ? 'captured-red' : 'captured-blue';
        this.targetRatio = friendlyIsWest ? friendlyRatio : 1 - friendlyRatio;

        const friendlyCount = snapshot.friendlyCount;
        const enemyCount = snapshot.enemyCount;
        const ownership = snapshot.ownership;
        const state = snapshot.captureState;

        if (state === 'securing') {
            const pct = Math.max(0, Math.min(100, Math.round(snapshot.secureProgress * 100)));
            this.setStatus(`SECURING ${pct}%`, 'securing');
            this.updateGlow();
            return;
        }

        if (state === 'clearing') {
            this.setStatus('CLEARING', 'capturing');
            this.updateGlow();
            return;
        }

        if (state === 'contested') {
            this.setStatus('CONTESTED', 'contested');
            this.updateGlow();
            return;
        }

        if (state === 'integrating') {
            this.setStatus('INTEGRATING', ownership === 'FRIENDLY' ? friendlyClass : enemyClass);
            this.updateGlow();
            return;
        }

        if (ownership === 'FRIENDLY') {
            if (enemyCount === 0) {
                this.setStatus('CAPTURED', friendlyClass);
            } else if (enemyCount > friendlyCount) {
                this.setStatus('LOSING GROUND', 'losing');
            } else {
                this.setStatus('DEFENDING', 'contested');
            }
        } else if (ownership === 'ENEMY') {
            if (friendlyCount === 0) {
                this.setStatus('ENEMY HELD', enemyClass);
            } else if (friendlyCount > enemyCount) {
                this.setStatus('CAPTURING', 'capturing');
            } else {
                this.setStatus('CONTESTED', 'contested');
            }
        } else if (friendlyCount > enemyCount) {
            this.setStatus('CAPTURING', 'capturing');
        } else {
            this.setStatus('CONTESTED', 'contested');
        }
        
        // Update glow effect
        this.updateGlow();
    }

    setStatus(text, className) {
        this.statusText.textContent = text;
        this.statusText.className = 'status-text';
        if (className) {
            this.statusText.classList.add(className);
        }
    }

    updateGlow() {
        this.barGlow.className = 'bar-glow';
        if (this.targetRatio > 0.7) {
            this.barGlow.classList.add('blue-glow');
        } else if (this.targetRatio < 0.3) {
            this.barGlow.classList.add('red-glow');
        }
    }

    startAnimation() {
        if (this.animationFrame) return;
        
        const animate = () => {
            // Smooth interpolation
            const diff = this.targetRatio - this.currentRatio;
            this.currentRatio += diff * 0.15;
            
            // Update bar widths
            const redWidth = (1 - this.currentRatio) * 100;
            const blueWidth = this.currentRatio * 100;
            
            this.redBar.style.width = redWidth + '%';
            this.blueBar.style.width = blueWidth + '%';
            this.separator.style.left = redWidth + '%';
            
            if (this.isVisible) {
                this.animationFrame = requestAnimationFrame(animate);
            }
        };
        
        this.animationFrame = requestAnimationFrame(animate);
    }
}

// Initialize
function initCaptureUI() {
    captureUI = new CaptureUI();
    window.FLOCapture = captureUI;
    console.log('FLO Capture UI initialized');
    
    // Notify Arma that UI is ready
    if (typeof A3API !== 'undefined' && typeof A3API.SendAlert === 'function') {
        A3API.SendAlert(JSON.stringify({ event: 'captureUI::ready' }));
    }
}

// Auto-initialize
if (document.readyState !== 'loading') {
    initCaptureUI();
} else {
    document.addEventListener('DOMContentLoaded', initCaptureUI, { once: true });
}

