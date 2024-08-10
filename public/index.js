document.addEventListener('DOMContentLoaded', function() {
  const logDiv = document.getElementById('log');

  function fetchLogs() {
    fetch('/log')
      .then(response => response.json())
      .then(data => {
		if (data.length === 0) {
			return;
		}
        const logList = document.createElement('ul');
        Object.keys(data).forEach(key => {
        const listItem = document.createElement('li');
            listItem.textContent = `${key}: ${Array.isArray(data[key]) ? data[key].join(', ') : data[key]}`;
            logList.appendChild(listItem);
        });
        logDiv.appendChild(logList);
        logDiv.scrollTop = logDiv.scrollHeight; // スクロールを最下部に
      })
      .catch(error => console.error('Error fetching logs:', error));
  }

  // 初回のログ取得
  fetchLogs();

  // 5秒ごとにログを取得
  setInterval(fetchLogs, 5000);
});
