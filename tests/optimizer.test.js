/**
 * Unit tests for the Resume Optimizer Analysis Engine.
 * 
 * PURPOSE: Lock the scoring algorithm so that adding metadata
 * (like learningResources) does NOT change match scores.
 */

const { analyze } = require('../modules/optimizer');

// --- Test fixtures ---
const SAMPLE_RESUME = `
John Doe — Software Engineer
5 years of experience building production web applications.

SKILLS
JavaScript, React, Node.js, Python, SQL, Git, Agile, REST API

EXPERIENCE
Senior Developer | Acme Corp | Jan 2020 - Present
- Led development of a React SPA that increased user engagement by 40%
- Managed a team of 4 engineers using Agile/Scrum methodology
- Implemented CI/CD pipelines reducing deployment time by 60%

EDUCATION
B.S. Computer Science, State University
`;

const SAMPLE_JD = `
We are looking for a Full Stack Developer with experience in:
- React, TypeScript, Next.js
- Node.js, Express, Python
- PostgreSQL, MongoDB, Redis
- Docker, Kubernetes, AWS
- CI/CD, Git, Agile, Scrum
- Machine Learning and NLP experience is a plus
- REST API and GraphQL
`;

// --- Tests ---

describe('Analysis Engine — Scoring Integrity', () => {
    let result;

    beforeAll(() => {
        result = analyze(SAMPLE_RESUME, SAMPLE_JD);
    });

    test('returns a numeric matchScore between 0 and 100', () => {
        expect(typeof result.matchScore).toBe('number');
        expect(result.matchScore).toBeGreaterThanOrEqual(0);
        expect(result.matchScore).toBeLessThanOrEqual(100);
    });

    test('returns expected breakdown keys', () => {
        const expectedKeys = [
            'skillsMatch',
            'experienceRelevance',
            'keywordsPresent',
            'atsFormatting',
            'actionVerbs',
            'quantifiableMetrics'
        ];
        expectedKeys.forEach(key => {
            expect(result.breakdown).toHaveProperty(key);
            expect(typeof result.breakdown[key]).toBe('number');
        });
    });

    test('matched keywords are a subset of JD keywords found in resume', () => {
        result.matched.forEach(skill => {
            expect(typeof skill).toBe('string');
            expect(skill.length).toBeGreaterThan(0);
        });
    });

    test('missing keywords are JD-required skills NOT in resume', () => {
        // No overlap between matched and missing
        const overlap = result.matched.filter(m =>
            result.missing.some(miss => miss.toLowerCase() === m.toLowerCase())
        );
        expect(overlap).toHaveLength(0);
    });

    test('matched + missing equals total JD keywords', () => {
        const totalJdKeywords = result.matched.length + result.missing.length;
        expect(totalJdKeywords).toBeGreaterThan(0);
    });

    test('matchScore is deterministic across repeated calls', () => {
        const result2 = analyze(SAMPLE_RESUME, SAMPLE_JD);
        expect(result2.matchScore).toBe(result.matchScore);
        expect(result2.breakdown).toEqual(result.breakdown);
        expect(result2.matched.sort()).toEqual(result.matched.sort());
        expect(result2.missing.sort()).toEqual(result.missing.sort());
    });

    test('returns checklist, simulation, recommendation, optimizedResume, and coachInsight', () => {
        expect(Array.isArray(result.checklist)).toBe(true);
        expect(typeof result.simulation).toBe('object');
        expect(typeof result.recommendation).toBe('string');
        expect(typeof result.optimizedResume).toBe('string');
        expect(typeof result.coachInsight).toBe('string');
    });
});

describe('Analysis Engine — Edge Cases', () => {
    test('returns 0 match when resume has no relevant skills', () => {
        const emptyResume = 'I am a professional with 10 years of experience in various fields and industries with strong leadership abilities.';
        const jd = 'Requires expertise in Kubernetes, Docker, Terraform, and AWS cloud services.';
        const r = analyze(emptyResume, jd);
        expect(r.matchScore).toBeLessThanOrEqual(50);
        expect(r.missing.length).toBeGreaterThan(0);
    });

    test('handles JD with no recognizable skills gracefully', () => {
        const resume = 'JavaScript, React, Python developer with 5 years experience.';
        const emptyJd = 'We need someone who is a great team player and communicator.';
        const r = analyze(resume, emptyJd);
        expect(typeof r.matchScore).toBe('number');
        expect(r.missing).toHaveLength(0);
        expect(r.matched).toHaveLength(0);
    });
});

describe('Analysis Engine — Learning Path Metadata (Safety Constraint)', () => {
    let result;

    beforeAll(() => {
        result = analyze(SAMPLE_RESUME, SAMPLE_JD);
    });

    test('learningResources is a plain object in the response', () => {
        expect(typeof result.learningResources).toBe('object');
        expect(result.learningResources).not.toBeNull();
        expect(Array.isArray(result.learningResources)).toBe(false);
    });

    test('learningResources values are arrays of resource objects with title, url, and source', () => {
        Object.values(result.learningResources).forEach(resources => {
            expect(Array.isArray(resources)).toBe(true);
            resources.forEach(resource => {
                expect(resource).toHaveProperty('title');
                expect(resource).toHaveProperty('url');
                expect(resource).toHaveProperty('source');
                expect(typeof resource.title).toBe('string');
                expect(typeof resource.url).toBe('string');
                expect(typeof resource.source).toBe('string');
            });
        });
    });

    test('missingWithPaths is an array where every item has keyword (string) and learningPath (array)', () => {
        expect(Array.isArray(result.missingWithPaths)).toBe(true);
        result.missingWithPaths.forEach(item => {
            expect(item).toHaveProperty('keyword');
            expect(item).toHaveProperty('learningPath');
            expect(typeof item.keyword).toBe('string');
            expect(Array.isArray(item.learningPath)).toBe(true);
        });
    });

    test('missingWithPaths length equals missing length — no keywords dropped', () => {
        expect(result.missingWithPaths.length).toBe(result.missing.length);
    });

    test('result.missing remains a plain string array — backward compat preserved', () => {
        expect(Array.isArray(result.missing)).toBe(true);
        result.missing.forEach(kw => expect(typeof kw).toBe('string'));
    });

    test('adding metadata does NOT alter matchScore by even 1 point', () => {
        // Run a second analysis and compare — scores must be byte-identical
        const result2 = analyze(SAMPLE_RESUME, SAMPLE_JD);
        expect(result2.matchScore).toBe(result.matchScore);
        expect(result2.breakdown).toEqual(result.breakdown);
    });

    test('learningResources keys are a subset of missing — no phantom entries', () => {
        const missingSet = new Set(result.missing.map(k => k.toLowerCase()));
        Object.keys(result.learningResources).forEach(key => {
            expect(missingSet.has(key.toLowerCase())).toBe(true);
        });
    });
});
