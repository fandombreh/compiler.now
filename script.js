document.getElementById('uploadForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const files = document.getElementById('files').files;
    const languages = Array.from(document.getElementById('languages').selectedOptions).map(opt => opt.value);
    const outputDiv = document.getElementById('output');

    if (files.length === 0) {
        outputDiv.textContent = 'Please upload at least one file.';
        return;
    }

    if (languages.length === 0) {
        outputDiv.textContent = 'Please select at least one language.';
        return;
    }

    const formData = new FormData();
    for (let file of files) {
        formData.append('files', file);
    }
    formData.append('languages', JSON.stringify(languages));

    try {
        const response = await fetch('/compile', {
            method: 'POST',
            body: formData
        });
        const result = await response.json();
        outputDiv.textContent = result.message;
        if (result.exeUrl) {
            const link = document.createElement('a');
            link.href = result.exeUrl;
            link.textContent = 'Download EXE';
            link.download = 'compiled.exe';
            outputDiv.appendChild(link);
        }
    } catch (error) {
        outputDiv.textContent = 'Error: ' + error.message;
    }
});
