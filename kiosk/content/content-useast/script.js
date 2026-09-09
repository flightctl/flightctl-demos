document.addEventListener('DOMContentLoaded', () => {
  fetch('products.json')
    .then(response => response.json())
    .then(products => {
      const grid = document.getElementById('product-grid');
      products.forEach((product, index) => {
        const card = document.createElement('div');
        card.className = 'card';
        card.style.animationDelay = `${index * 0.2}s`;

        const image = document.createElement('img');
        image.src = product.image;
        image.alt = product.name;
        const content = document.createElement('div');
        content.className = 'card-content';
        for (const [tag, value] of [['h2', product.name], ['p', product.description], ['p', product.price]]) {
          const element = document.createElement(tag);
          element.textContent = value;
          content.appendChild(element);
        }
        card.append(image, content);
        grid.appendChild(card);
      });
    })
    .catch(error => {
      console.error('Error loading products:', error);
    });
});
