document.addEventListener("DOMContentLoaded", () => {
    // Auto-hide alerts
    const alerts = document.querySelectorAll('.alert');
    alerts.forEach(alert => {
        setTimeout(() => { alert.style.opacity = '0'; setTimeout(() => alert.remove(), 500); }, 3000);
    });

    // Confirm Delete
    const deleteForms = document.querySelectorAll('form[action*="delete"]');
    deleteForms.forEach(form => {
        form.addEventListener('submit', (e) => {
            if (!confirm("Are you sure you want to delete this material?")) e.preventDefault();
        });
    });
});