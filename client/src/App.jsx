import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  FileText,
  Target,
  CheckCircle2,
  AlertCircle,
  ArrowRight,
  RefreshCcw,
  Download,
  Copy,
  Layout,
  Star,
  Check,
  UserCheck,
  Zap,
  Briefcase,
  Edit3,
  Undo2,
  ChevronRight,
  ShieldCheck,
  XCircle,
  BarChart3,
  Settings
} from 'lucide-react';
import axios from 'axios';

const App = () => {
  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [resumeText, setResumeText] = useState('');
  const [jdText, setJdText] = useState('');
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);
  const [copied, setCopied] = useState(false);
  const [viewOptimized, setViewOptimized] = useState(false);
  const [atsSimulation, setAtsSimulation] = useState(false);

  const analyzeResume = async () => {
    if (resumeText.trim().length < 50 || jdText.trim().length < 20) {
      setError("Provide more text for a professional alignment analysis.");
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const response = await axios.post('/api/optimize', {
        resumeText,
        jobDescriptionText: jdText
      });
      setResult(response.data);
      setStep(3);
    } catch (err) {
      setError(err.response?.data?.error || "Analysis failed.");
    } finally {
      setLoading(false);
    }
  };

  const copyOptimized = () => {
    navigator.clipboard.writeText(result.optimizedResume);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const downloadOptimized = () => {
    const blob = new Blob([result.optimizedResume], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `Optimized_Resume.txt`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="max-w-7xl mx-auto px-6 py-12">
      <header className="flex items-center justify-between mb-16 border-b border-white/5 pb-8">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 bg-gradient-to-br from-primary to-secondary rounded-2xl flex items-center justify-center text-white shadow-lg">
            <Briefcase className="w-7 h-7" />
          </div>
          <div>
            <span className="text-3xl font-black tracking-tighter italic block">OPTIRESUME <span className="text-primary font-normal text-sm align-top lowercase">Coach</span></span>
            <span className="text-[10px] uppercase tracking-[0.2em] text-white/40 font-bold italic">Intelligence Roadmap v1.0</span>
          </div>
        </div>
        {step === 3 && (
          <button onClick={() => setStep(1)} className="bg-white/5 hover:bg-white/10 px-6 py-3 rounded-xl transition-all font-bold border border-white/10 text-xs uppercase tracking-widest flex items-center gap-2">
            <Undo2 className="w-4 h-4" /> New Session
          </button>
        )}
      </header>

      <AnimatePresence mode="wait">
        {step === 1 && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-12">
            <div className="text-center space-y-4 max-w-4xl mx-auto">
              <div className="inline-flex items-center gap-2 bg-primary/10 text-primary px-4 py-1 rounded-full text-[10px] font-black uppercase tracking-widest border border-primary/20 mb-4">
                <Zap className="w-3 h-3" /> MVP Roadmap Features Enabled
              </div>
              <h1 className="text-7xl font-black leading-[1.1] tracking-tight bg-clip-text text-transparent bg-gradient-to-b from-white to-white/40">
                Data-Driven Career <br /> Intelligence.
              </h1>
              <p className="text-xl text-white/40 max-w-2xl mx-auto font-light leading-relaxed font-italic">
                Complete transparency for your ATS alignment. Paste your data and see exactly what recruiters see.
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-8 h-[400px]">
              <div className="glass p-10 flex flex-col h-full border-white/5 border">
                <div className="flex items-center gap-4 mb-6">
                  <div className="p-3 bg-primary/20 rounded-xl text-primary"><Edit3 className="w-6 h-6" /></div>
                  <h3 className="text-xl font-black italic tracking-tight uppercase">Resume Content</h3>
                </div>
                <textarea
                  className="w-full flex-grow bg-black/40 border-2 border-white/5 rounded-3xl p-8 focus:ring-4 focus:ring-primary/10 focus:outline-none transition-all resize-none text-white/90 font-mono text-sm leading-relaxed"
                  placeholder="Paste resume here..."
                  value={resumeText}
                  onChange={(e) => setResumeText(e.target.value)}
                />
              </div>
              <div className="glass p-10 flex flex-col h-full border-white/5 border">
                <div className="flex items-center gap-4 mb-6">
                  <div className="p-3 bg-secondary/20 rounded-xl text-secondary"><Target className="w-6 h-6" /></div>
                  <h3 className="text-xl font-black italic tracking-tight uppercase">Job Description</h3>
                </div>
                <textarea
                  className="w-full flex-grow bg-black/40 border-2 border-white/5 rounded-3xl p-8 focus:ring-4 focus:ring-secondary/10 focus:outline-none transition-all resize-none text-white/90 font-mono text-sm leading-relaxed"
                  placeholder="Paste JD requirements here..."
                  value={jdText}
                  onChange={(e) => setJdText(e.target.value)}
                />
              </div>
            </div>

            <div className="flex flex-col items-center gap-4 pt-12">
              <button onClick={analyzeResume} disabled={loading} className="btn-primary px-20 py-6 text-2xl flex items-center gap-4 group">
                {loading ? <RefreshCcw className="animate-spin" /> : <>PERFORM DEEP SCAN <ArrowRight className="group-hover:translate-x-2 transition-transform" /></>}
              </button>
            </div>
            {error && <p className="text-center text-red-400 font-bold">{error}</p>}
          </motion.div>
        )}

        {step === 3 && result && (
          <motion.div initial={{ opacity: 0, y: 30 }} animate={{ opacity: 1, y: 0 }} className="space-y-12 pb-24">
            {/* Header Stats */}
            <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
              <div className="glass p-10 text-center flex flex-col items-center justify-center space-y-4 border border-white/10 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-full h-1 bg-primary" />
                <span className="text-7xl font-black italic tracking-tighter text-white">{result.matchScore}%</span>
                <span className="text-white/40 uppercase tracking-[0.3em] text-[10px] font-black">OVERALL MATCH</span>
                <p className="text-xs text-white/60 font-medium leading-relaxed uppercase italic mt-4">{result.recommendation}</p>
              </div>

              <div className="lg:col-span-3 glass p-10 border border-white/10 flex items-center gap-8 bg-gradient-to-r from-primary/5 to-transparent">
                <div className="w-20 h-20 bg-primary/20 rounded-full flex items-center justify-center shrink-0 border border-primary/20">
                  <Zap className="w-10 h-10 text-primary" />
                </div>
                <div className="space-y-2">
                  <p className="text-primary font-black uppercase tracking-widest text-xs italic">Senior Coach Insight</p>
                  <p className="text-2xl font-bold leading-tight text-white/90">"{result.coachInsight}"</p>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
              {/* Score Breakdown (Left) */}
              <div className="space-y-8">
                <div className="glass p-8 space-y-6 border border-white/5">
                  <div className="flex items-center justify-between">
                    <h4 className="text-lg font-black italic uppercase tracking-tight flex items-center gap-2"><BarChart3 className="w-5 h-5" /> Score Breakdown</h4>
                    <span className="text-[10px] text-white/30 font-bold uppercase tracking-widest">Transparency Layer</span>
                  </div>
                  <div className="space-y-5">
                    {Object.entries(result.breakdown).map(([key, val]) => (
                      <div key={key} className="space-y-2">
                        <div className="flex justify-between text-[11px] font-black uppercase tracking-widest text-white/40">
                          <span>{key.replace(/([A-Z])/g, ' $1')}</span>
                          <span>{val}%</span>
                        </div>
                        <div className="h-2 bg-white/5 rounded-full overflow-hidden">
                          <motion.div initial={{ width: 0 }} animate={{ width: `${val}%` }} className="h-full bg-primary" />
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* ATS Simulation Toggle Card */}
                <div className="glass p-8 border border-white/5 space-y-6 relative overflow-hidden">
                  <div className="flex items-center justify-between">
                    <h4 className="text-lg font-black italic uppercase tracking-tight flex items-center gap-2"><Layout className="w-5 h-5" /> ATS Simulation</h4>
                    <button
                      onClick={() => setAtsSimulation(!atsSimulation)}
                      className={`relative w-12 h-6 rounded-full transition-all ${atsSimulation ? 'bg-primary' : 'bg-white/10'}`}
                    >
                      <motion.div animate={{ x: atsSimulation ? 24 : 4 }} className="w-4 h-4 bg-white rounded-full mt-1 shadow-lg" />
                    </button>
                  </div>
                  <p className="text-xs text-white/40 leading-relaxed italic">Switch to simulate how specific platforms score your formatting vs keywords.</p>
                  {atsSimulation && (
                    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-4 pt-2">
                      {Object.values(result.simulation).map((sim, i) => (
                        <div key={i} className="flex items-center justify-between bg-black/40 p-4 rounded-xl border border-white/5">
                          <div>
                            <p className="text-[10px] font-black uppercase tracking-widest text-white/40">{sim.name}</p>
                            <p className="text-xs text-white/80 font-bold">{sim.advice}</p>
                          </div>
                          <div className={`text-xl font-black ${sim.score > 50 ? 'text-green-400' : 'text-yellow-400'}`}>{sim.score}%</div>
                        </div>
                      ))}
                    </motion.div>
                  )}
                </div>
              </div>

              {/* Central Actions & Match Lists (Right) */}
              <div className="lg:col-span-2 space-y-8">
                {/* Action Checklist */}
                <div className="glass p-8 border border-primary/20 space-y-6 bg-primary/5">
                  <h4 className="text-lg font-black italic uppercase tracking-tight flex items-center gap-2 text-primary font-italic leading-none">
                    <CheckCircle2 className="w-5 h-5" /> Action Checklist: One-Click Fixes
                  </h4>
                  <div className="space-y-4">
                    {result.checklist.map((item, i) => (
                      <div key={i} className="bg-black/60 border border-white/10 p-6 rounded-2xl flex items-center justify-between group hover:border-primary/40 transition-all">
                        <div className="space-y-2">
                          <div className="flex items-center gap-3">
                            <span className="text-[10px] bg-primary/20 text-primary px-2 py-0.5 rounded font-black uppercase tracking-widest">Impact: {item.impact}</span>
                            <h5 className="font-bold text-white leading-tight uppercase text-sm italic tracking-tight">{item.title}</h5>
                          </div>
                          <div className="flex flex-wrap gap-2 pt-1">
                            {item.items.map((sub, j) => (
                              <span key={j} className="text-[11px] text-white/40 bg-white/5 px-2 py-0.5 rounded border border-white/5">{sub}</span>
                            ))}
                          </div>
                        </div>
                        <button
                          onClick={() => setViewOptimized(true)}
                          className="bg-primary text-white p-3 rounded-xl shadow-lg shadow-primary/20 opacity-0 group-hover:opacity-100 transition-all hover:scale-105"
                        >
                          <Zap className="w-5 h-5" />
                        </button>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Keyword Visualization */}
                <div className="glass p-8 border border-white/5 space-y-8">
                  <div className="flex items-center justify-between border-b border-white/5 pb-6">
                    <h4 className="text-lg font-black italic uppercase tracking-tight flex items-center gap-2"><ShieldCheck className="w-5 h-5 text-green-400" /> Technical Keyword Map</h4>
                    <div className="flex gap-4 text-[10px] font-black uppercase tracking-widest">
                      <span className="flex items-center gap-1.5 text-green-400"><div className="w-1.5 h-1.5 bg-green-400 rounded-full" /> Full Match</span>
                      <span className="flex items-center gap-1.5 text-red-500"><div className="w-1.5 h-1.5 bg-red-500 rounded-full" /> Critical Gap</span>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                    <div className="space-y-4">
                      <p className="text-[11px] font-black uppercase tracking-widest text-white/30 flex justify-between">Verified technical skills ({result.matched.length}) <span>Green Zone</span></p>
                      <div className="flex flex-wrap gap-2">
                        {result.matched.map((m, i) => (
                          <span key={i} className="bg-green-400/10 border border-green-400/20 text-green-400 text-xs px-3 py-1.5 rounded-lg font-bold flex items-center gap-2">
                            <Check className="w-3 h-3" /> {m}
                          </span>
                        ))}
                        {result.matched.length === 0 && <p className="text-white/20 italic text-xs">No technical matches detected.</p>}
                      </div>
                    </div>

                    <div className="space-y-4">
                      <p className="text-[11px] font-black uppercase tracking-widest text-white/30 flex justify-between font-italic">Missing critical gaps ({result.missing.length}) <span className="text-red-500 italic">Danger Zone</span></p>
                      <div className="flex flex-wrap gap-2">
                        {result.missing.map((m, i) => (
                          <span key={i} className="bg-red-400/10 border border-red-400/20 text-red-400 text-xs px-3 py-1.5 rounded-lg font-bold flex items-center gap-2 italic">
                            <XCircle className="w-3 h-3" /> {m}
                          </span>
                        ))}
                        {result.missing.length === 0 && <p className="text-green-400 italic text-sm font-black tracking-tight flex items-center gap-2"><CheckCircle2 className="w-4 h-4" /> Perfect Semantic Alignment</p>}
                      </div>
                    </div>
                  </div>
                </div>

                {/* Resume View Toggle */}
                <div className="glass p-2 border border-white/5">
                  <div className="flex p-4 gap-4">
                    <button
                      onClick={() => setViewOptimized(false)}
                      className={`flex-1 py-4 rounded-2xl font-black uppercase text-[10px] tracking-widest transition-all ${!viewOptimized ? 'bg-white text-black' : 'text-white/40 hover:bg-white/10'}`}
                    >
                      Source Resume
                    </button>
                    <button
                      onClick={() => setViewOptimized(true)}
                      className={`flex-1 py-4 rounded-2xl font-black uppercase text-[10px] tracking-widest transition-all flex items-center justify-center gap-2 ${viewOptimized ? 'bg-primary text-white shadow-lg' : 'text-white/40 hover:bg-white/10'}`}
                    >
                      <ShieldCheck className="w-4 h-4" /> Optimized Blueprint
                    </button>
                  </div>
                  <div className="p-6 pt-0">
                    <div className="bg-black/60 rounded-3xl p-8 max-h-[400px] overflow-y-auto font-mono text-xs leading-relaxed text-white/80 whitespace-pre-wrap relative">
                      {viewOptimized ? result.optimizedResume : resumeText}
                      {viewOptimized && (
                        <div className="sticky bottom-4 right-4 flex justify-end gap-2">
                          <button onClick={copyOptimized} className={`p-3 rounded-xl transition-all ${copied ? 'bg-green-500' : 'bg-primary hover:scale-105 shadow-xl text-white'}`}>
                            {copied ? <Check className="w-5 h-5" /> : <Copy className="w-5 h-5" />}
                          </button>
                          <button onClick={downloadOptimized} className="p-3 bg-secondary hover:scale-105 shadow-xl rounded-xl transition-all text-white">
                            <Download className="w-5 h-5" />
                          </button>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Footer Branding */}
      <footer className="mt-20 pt-12 border-t border-white/5 text-center space-y-2 pb-12">
        <div className="flex items-center justify-center gap-2 text-white/40 text-[10px] font-black uppercase tracking-[0.2em]">
          <span className="flex items-center gap-1.5">Built with <Star className="w-2.5 h-2.5 text-primary fill-primary" /> by</span>
          <span className="text-white hover:text-primary transition-colors duration-300">Apollo Technologies US</span>
        </div>
        <p className="text-white/20 text-[9px] font-bold tracking-widest uppercase">Prosper, TX.</p>
      </footer>
    </div>
  );
};

export default App;
