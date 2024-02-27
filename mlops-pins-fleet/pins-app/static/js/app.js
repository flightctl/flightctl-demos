// Établir une connexion WebSocket avec le serveur.
const socket = new WebSocket('ws://pins-redhat.local:30000/video');

// Écouter l'événement 'message' qui est émis lorsque le serveur envoie un message.
socket.addEventListener('message', function (event) {
    // Mettre à jour l'attribut 'src' de l'image avec les données reçues du serveur.
    document.getElementById('dynamicImage').src = event.data;
});

// Gérer les erreurs de connexion WebSocket.
socket.addEventListener('error', function (error) {
    console.error('WebSocket Error:', error);
});

// Gérer la fermeture de la connexion WebSocket.
socket.addEventListener('close', function () {
    console.log('WebSocket connection closed.');
});
