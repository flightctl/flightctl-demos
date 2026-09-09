document.addEventListener('DOMContentLoaded', () => {
  fetch('products.json')
    .then(response => response.json())
    .then(products => {
      const grid = document.getElementById('product-grid');
      products.forEach((product, index) => {
        const card = document.createElement('div');
        card.className = 'card';
        card.style.animationDelay = `${index * 0.2}s`;

        card.innerHTML = `
          <img src="${product.image}" alt="${product.name}" />
          <div class="card-content">
            <h2>${product.name}</h2>
            <p>${product.description}</p>
            <p>${product.price}</p>
          </div>
        `;
        grid.appendChild(card);
      });
    })
    .catch(error => {
      console.error('Error loading products:', error);
    });
});

