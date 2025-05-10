// Configure your import map in config/importmap.rb

// Import Bootstrap JS
import "bootstrap"

// Custom JavaScript for the Support Bot app

// Initialize the application when the DOM is loaded
document.addEventListener("DOMContentLoaded", function() {
  // Initialize chat functionality
  initChat();
  
  // Initialize voice functionality
  initVoice();
});

// Chat functionality
function initChat() {
  const chatForms = document.querySelectorAll('.chat-input form');
  if (!chatForms.length) return;
  
  chatForms.forEach(form => {
    form.addEventListener('submit', function(e) {
      e.preventDefault();
      const input = this.querySelector('input');
      const message = input.value.trim();
      
      if (message) {
        // Add user message to chat
        addMessage(message, 'user');
        
        // Clear input
        input.value = '';
        
        // Get the customer ID from the current URL
        const pathParts = window.location.pathname.split('/');
        const customerId = pathParts[pathParts.indexOf('customers') + 1];
        
        // Show typing indicator
        showTypingIndicator();
        
        // Make API call to ask endpoint
        fetch(`/customers/${customerId}/ask`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
          },
          body: JSON.stringify({ question: message })
        })
        .then(response => response.json())
        .then(data => {
          // Hide typing indicator
          hideTypingIndicator();
          
          // Display bot response
          addMessage(data.response, 'bot');
        })
        .catch(error => {
          // Hide typing indicator
          hideTypingIndicator();
          
          // Display error message
          addMessage("Sorry, I encountered an error while processing your request.", 'bot');
          console.error('Error:', error);
        });
      }
    });
  });
}

// Show typing indicator
function showTypingIndicator() {
  const chatMessages = document.querySelector('.chat-messages');
  if (!chatMessages) return;
  
  const typingDiv = document.createElement('div');
  typingDiv.className = 'message bot-message typing-indicator mb-3';
  typingDiv.innerHTML = `
    <div class="message-content p-2 rounded">
      <p class="mb-0">
        <span class="typing-dot"></span>
        <span class="typing-dot"></span>
        <span class="typing-dot"></span>
      </p>
    </div>
  `;
  
  chatMessages.appendChild(typingDiv);
  chatMessages.scrollTop = chatMessages.scrollHeight;
}

// Hide typing indicator
function hideTypingIndicator() {
  const typingIndicator = document.querySelector('.typing-indicator');
  if (typingIndicator) {
    typingIndicator.remove();
  }
}

// Add a message to the chat
function addMessage(message, sender) {
  const chatMessages = document.querySelector('.chat-messages');
  if (!chatMessages) return;
  
  const messageDiv = document.createElement('div');
  messageDiv.className = `message ${sender}-message mb-3`;
  
  const messageContent = document.createElement('div');
  messageContent.className = 'message-content p-2 rounded';
  
  const messagePara = document.createElement('p');
  messagePara.className = 'mb-0';
  messagePara.textContent = message;
  
  messageContent.appendChild(messagePara);
  messageDiv.appendChild(messageContent);
  chatMessages.appendChild(messageDiv);
  
  // Scroll to bottom
  chatMessages.scrollTop = chatMessages.scrollHeight;
}

// Voice functionality
function initVoice() {
  const micButtons = document.querySelectorAll('.mic-button');
  if (!micButtons.length) return;
  
  micButtons.forEach(button => {
    button.addEventListener('click', function() {
      const voiceStatus = document.querySelector('.voice-status .badge');
      const transcript = document.querySelector('.voice-transcript');
      
      if (voiceStatus.classList.contains('bg-secondary')) {
        // Start listening
        voiceStatus.textContent = 'Listening...';
        voiceStatus.classList.remove('bg-secondary');
        voiceStatus.classList.add('bg-danger');
        
        // Simulate voice recording and transcription
        transcript.innerHTML = '<p class="text-center">Simulating voice recognition...</p>';
        
        // After a delay, show a simulated transcript
        setTimeout(() => {
          const sampleQuestion = "How many orders were placed yesterday?";
          transcript.innerHTML = `<p>${sampleQuestion}</p>`;
          
          // Get the customer ID from the current URL
          const pathParts = window.location.pathname.split('/');
          const customerId = pathParts[pathParts.indexOf('customers') + 1];
          
          // Make API call to voice endpoint
          fetch(`/customers/${customerId}/voice`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
            },
            body: JSON.stringify({ transcript: sampleQuestion })
          })
          .then(response => response.json())
          .then(data => {
            // Stop listening
            voiceStatus.textContent = 'Not listening';
            voiceStatus.classList.remove('bg-danger');
            voiceStatus.classList.add('bg-secondary');
            
            // Add the transcript to the chat and the response
            if (document.querySelector('.chat-messages')) {
              addMessage(data.transcript, 'user');
              setTimeout(() => {
                addMessage(data.response, 'bot');
              }, 500);
            }
          })
          .catch(error => {
            // Stop listening
            voiceStatus.textContent = 'Not listening';
            voiceStatus.classList.remove('bg-danger');
            voiceStatus.classList.add('bg-secondary');
            
            console.error('Error:', error);
          });
        }, 2000);
      } else {
        // Stop listening
        voiceStatus.textContent = 'Not listening';
        voiceStatus.classList.remove('bg-danger');
        voiceStatus.classList.add('bg-secondary');
      }
    });
  });
} 