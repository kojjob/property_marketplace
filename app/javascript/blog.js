// Blog functionality
document.addEventListener('DOMContentLoaded', function() {
  // Comment reply functionality
  document.addEventListener('click', function(e) {
    if (e.target.classList.contains('reply-button') || e.target.closest('.reply-button')) {
      e.preventDefault();
      const button = e.target.classList.contains('reply-button') ? e.target : e.target.closest('.reply-button');
      const commentId = button.dataset.commentId;
      const replyForm = document.getElementById(`reply-form-${commentId}`);

      if (replyForm) {
        replyForm.classList.toggle('hidden');

        // Scroll to form if showing
        if (!replyForm.classList.contains('hidden')) {
          replyForm.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
      }
    }
  });

  // Auto-hide reply forms when clicking outside
  document.addEventListener('click', function(e) {
    if (!e.target.closest('.reply-button') && !e.target.closest('[id^="reply-form-"]')) {
      document.querySelectorAll('[id^="reply-form-"]').forEach(form => {
        form.classList.add('hidden');
      });
    }
  });

  // Handle comment form submissions with Turbo
  document.addEventListener('turbo:submit-start', function(e) {
    if (e.target.matches('form[action*="/comments"]')) {
      const submitButton = e.target.querySelector('input[type="submit"], button[type="submit"]');
      if (submitButton) {
        submitButton.disabled = true;
        submitButton.textContent = 'Posting...';
      }
    }
  });

  // Handle successful comment submissions
  document.addEventListener('turbo:submit-end', function(e) {
    if (e.target.matches('form[action*="/comments"]')) {
      const submitButton = e.target.querySelector('input[type="submit"], button[type="submit"]');
      if (submitButton) {
        submitButton.disabled = false;
        submitButton.textContent = 'Post Comment';
      }
    }
  });
});