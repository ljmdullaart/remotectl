// Main JavaScript file for IR Remote Control

const API_BASE = window.location.origin;

// Send IR command
async function sendCommand(buttonId) {
    const outputBox = document.getElementById('output');
    const button = document.getElementById(buttonId);
    
    // Disable all buttons
    const buttons = document.querySelectorAll('.ir-button');
    buttons.forEach(btn => btn.disabled = true);
    
    
    // Show loading message
    outputBox.innerHTML = '<p class="info">⏳ Sending IR command: ' + buttonId + '...</p>';
    
    try {
        const response = await fetch(`${API_BASE}/api/execute`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ argument: buttonId })
        });
        
        const result = await response.json();
        
        // Display output
        if (result.success) {
            outputBox.innerHTML = `<p class="success">✓ Command executed successfully (exit code: ${result.exit_code})</p>\n<p class="info">Argument: ${result.argument}</p>\n<hr style="border: 1px solid #444; margin: 10px 0;">\n${escapeHtml(result.output)}`;
        } else {
            outputBox.innerHTML = `<p class="error">✗ Command failed (exit code: ${result.exit_code})</p>\n<p class="info">Argument: ${result.argument}</p>\n<hr style="border: 1px solid #444; margin: 10px 0;">\n${escapeHtml(result.output)}`;
        }
        
        // Scroll to bottom of output
        outputBox.scrollTop = outputBox.scrollHeight;
        
    } catch (error) {
        console.error('Error executing command:', error);
        outputBox.innerHTML = `<p class="error">✗ Error executing command: ${escapeHtml(error.message)}</p>`;
    } finally {
        // Re-enable buttons
        buttons.forEach(btn => {
            btn.disabled = false;
            btn.classList.remove('executing');
        });
    }
}

// Escape HTML to prevent XSS
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Make sendCommand available globally
window.sendCommand = sendCommand;
