document.getElementById('uploadForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const files = document.getElementById('files').files;
    const main_language = document.getElementById('main_language').value;
    const additional_languages = Array.from(document.getElementById('additional_languages').selectedOptions).map(opt => opt.value);
    const outputDiv = document.getElementById('output');

    if (files.length === 0) {
        outputDiv.textContent = 'Please upload at least one C++ file.';
        return;
    }

    let hasCpp = false;
    for (let file of files) {
        if (file.name.endsWith('.cpp')) {
            hasCpp = true;
            break;
        }
    }
    if (!hasCpp) {
        outputDiv.textContent = 'At least one C++ file is required.';
        return;
    }

    const formData = new FormData();
    for (let file of files) {
        formData.append('files', file);
    }
    formData.append('main_language', main_language);
    formData.append('additional_languages', JSON.stringify(additional_languages));

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
