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

    update(ratio, bluforCount, opforCount, owner) {
        this.targetRatio = Math.max(0, Math.min(1, ratio));
        
        // Update status text based on situation
        const total = bluforCount + opforCount;
        
        // Default owner to EAST if not provided (safety)
        const currentOwner = owner || "EAST";
        
        if (currentOwner === "WEST") {
            // WE OWN IT
            if (opforCount === 0) {
                this.setStatus('CAPTURED', 'captured-blue');
            } else if (opforCount > bluforCount) {
                this.setStatus('LOSING GROUND', 'losing');
            } else {
                this.setStatus('DEFENDING', 'contested');
            }
        } else {
            // ENEMY OWNS IT (EAST/GUER)
            if (bluforCount === 0) {
                this.setStatus('ENEMY HELD', 'captured-red');
            } else if (bluforCount > opforCount) {
                this.setStatus('CAPTURING', 'capturing');
            } else {
                this.setStatus('CONTESTED', 'contested');
            }
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
    console.log('FLO Capture UI initialized');
    
    // Notify Arma that UI is ready
    if (typeof A3API !== 'undefined' && typeof A3API.SendAlert === 'function') {
        A3API.SendAlert(JSON.stringify({ event: 'captureUI::ready' }));
    }
}

// Global API for SQF calls
function showCaptureUI(objectiveName) {
    if (captureUI) captureUI.show(objectiveName);
}

function hideCaptureUI() {
    if (captureUI) captureUI.hide();
}

function updateCaptureUI(ratio, bluforCount, opforCount, owner) {
    if (captureUI) captureUI.update(ratio, bluforCount, opforCount, owner);
}

// Auto-initialize
if (document.readyState !== 'loading') {
    initCaptureUI();
} else {
    document.addEventListener('DOMContentLoaded', initCaptureUI, { once: true });
}

