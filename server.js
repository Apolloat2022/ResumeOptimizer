const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const { analyze } = require('./modules/optimizer');

const app = express();
const port = 5000;

app.use(cors());
app.use(express.json({ limit: '5mb' }));

// API Endpoints
app.get('/api/health', (req, res) => res.json({ status: 'ok' }));

app.post('/api/optimize', (req, res) => {
    try {
        const { resumeText, jobDescriptionText } = req.body;

        if (!resumeText || resumeText.trim().length < 50) {
            return res.status(400).json({ error: 'Resume text is too search or missing. Please paste your full professional history.' });
        }

        if (!jobDescriptionText || jobDescriptionText.trim().length < 20) {
            return res.status(400).json({ error: 'Job description text is too short. Please provide the full role requirements.' });
        }

        console.log(`[DEBUG] Optimizing Resume (${resumeText.length} chars) vs JD (${jobDescriptionText.length} chars)`);
        const analysisResults = analyze(resumeText, jobDescriptionText);

        res.json({ status: 'success', ...analysisResults });
    } catch (err) {
        console.error('[ERROR] /api/optimize:', err.message);
        res.status(500).json({
            error: 'Analysis Failed',
            message: 'An internal error occurred. Please try again.'
        });
    }
});

// Resilient SPA Serving for Node 25 / Express 5
const distPath = path.resolve(__dirname, 'client', 'dist');
if (fs.existsSync(distPath)) {
    // Serve static files first
    app.use(express.static(distPath));

    // Fallback for SPA routing
    app.use((req, res, next) => {
        if (!req.url.startsWith('/api') && req.method === 'GET') {
            res.sendFile(path.join(distPath, 'index.html'));
        } else {
            next();
        }
    });
}

app.listen(port, () => console.log(`🚀 TEXT OPTIMIZER ENGINE active on http://localhost:${port}`));

module.exports = app;
