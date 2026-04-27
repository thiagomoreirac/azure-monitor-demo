const express = require('express');
const path = require('path');

// Initialize Application Insights
const appInsights = require('applicationinsights');
appInsights.setup(process.env.APPLICATIONINSIGHTS_CONNECTION_STRING || 'InstrumentationKey=your-instrumentation-key;IngestionEndpoint=https://your-region.in.applicationinsights.azure.com/;LiveEndpoint=https://your-region.livediagnostics.monitor.azure.com/;ApplicationId=your-application-id')
    .setAutoDependencyCorrelation(true)
    .setAutoCollectRequests(true)
    .setAutoCollectPerformance(true, true)
    .setAutoCollectExceptions(true)
    .setAutoCollectDependencies(true)
    .setAutoCollectConsole(true)
    .setUseDiskRetryCaching(true)
    .setSendLiveMetrics(true)
    .start();

const client = appInsights.defaultClient;

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// In-memory data for demo - Insurance/Claims domain
let claims = [
    { id: 1, policyNumber: 'POL-2024-001', claimType: 'Auto', amount: 5000, status: 'pending', submittedDate: '2024-04-20' },
    { id: 2, policyNumber: 'POL-2024-002', claimType: 'Home', amount: 15000, status: 'processing', submittedDate: '2024-04-18' },
    { id: 3, policyNumber: 'POL-2024-003', claimType: 'Health', amount: 3000, status: 'approved', submittedDate: '2024-04-15' },
    { id: 4, policyNumber: 'POL-2024-004', claimType: 'Auto', amount: 8500, status: 'flagged_fraud', submittedDate: '2024-04-22' },
    { id: 5, policyNumber: 'POL-2024-005', claimType: 'Travel', amount: 2000, status: 'rejected', submittedDate: '2024-04-10' }
];

// Routes
app.get('/', (req, res) => {
    client.trackEvent({ name: 'HomePage_Visited', properties: { tenant: 'customerA', domain: 'insurance-claims' } });
    res.send(`
<!DOCTYPE html>
<html>
<head>
    <title>CustomerA Claims Platform - Azure Monitor</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #0078d4; text-align: center; margin-bottom: 10px; }
        .subtitle { text-align: center; color: #666; margin-bottom: 30px; }
        .nav { display: flex; justify-content: center; gap: 20px; margin-bottom: 30px; flex-wrap: wrap; }
        .nav a { background: #0078d4; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; transition: background 0.3s; }
        .nav a:hover { background: #106ebe; }
        .info { background: #e6f3ff; padding: 20px; border-radius: 5px; margin-bottom: 20px; border-left: 4px solid #0078d4; }
        .status { display: flex; gap: 20px; margin-bottom: 20px; flex-wrap: wrap; }
        .status-item { background: #f8f9fa; padding: 15px; border-radius: 5px; flex: 1; min-width: 200px; text-align: center; }
        .status-value { font-size: 24px; font-weight: bold; color: #0078d4; }
        footer { text-align: center; margin-top: 30px; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏢 CustomerA Insurance Claims Platform</h1>
        <p class="subtitle">Observability & Monitoring for Claims Processing & Fraud Detection</p>
        
        <div class="info">
            <h3>✅ Application Insights Active</h3>
            <p>This demo application is instrumented with Application Insights and generating telemetry data for claims processing, fraud detection, and operational monitoring in real-time.</p>
        </div>

        <div class="nav">
            <a href="/health">Health Check</a>
            <a href="/api/claims">Claims API</a>
            <a href="/api/submit-claim">Submit Claim</a>
            <a href="/error">Generate Error</a>
            <a href="/load">Load Test</a>
            <a href="/fraud-check">Fraud Detection</a>
        </div>

        <div class="status">
            <div class="status-item">
                <div class="status-value">✅</div>
                <div>System Status</div>
            </div>
            <div class="status-item">
                <div class="status-value">${claims.length}</div>
                <div>Active Claims</div>
            </div>
            <div class="status-item">
                <div class="status-value">🟢</div>
                <div>Monitoring Active</div>
            </div>
            <div class="status-item">
                <div class="status-value">⚡</div>
                <div>Real-time Telemetry</div>
            </div>
        </div>

        <h3>📊 Demo Features</h3>
        <ul>
            <li><strong>Claim Submission:</strong> Track claim intake and processing workflows</li>
            <li><strong>Fraud Detection:</strong> Monitor fraud detection model performance and flagged claims</li>
            <li><strong>Health Monitoring:</strong> System health and availability tracking</li>
            <li><strong>Performance Metrics:</strong> Claim processing time, API latency, and throughput</li>
            <li><strong>Load Testing:</strong> Simulate peak claim submission periods</li>
            <li><strong>Error Tracking:</strong> Monitor claim processing failures and exceptions</li>
        </ul>

        <footer>
            <p>CustomerA Claims Platform - Node.js + Application Insights | Server Time: ${new Date().toISOString()}</p>
        </footer>
    </div>
</body>
</html>
    `);
});

app.get('/health', (req, res) => {
    const startTime = Date.now();
    
    client.trackEvent({ name: 'Health_Check_Requested', properties: { tenant: 'customerA' } });
    
    const health = {
        status: 'healthy',
        tenant: 'customerA',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        environment: process.env.NODE_ENV || 'development',
        version: '1.0.0'
    };
    
    const duration = Date.now() - startTime;
    client.trackMetric({ name: 'Health_Check_Duration', value: duration, properties: { tenant: 'customerA' } });
    client.trackDependency({ 
        target: 'internal', 
        name: 'health_check', 
        data: 'health status verification', 
        duration: duration, 
        resultCode: 200, 
        success: true,
        properties: { tenant: 'customerA' }
    });
    
    res.json(health);
});

app.get('/api/claims', (req, res) => {
    const startTime = Date.now();
    
    client.trackEvent({ 
        name: 'Claims_API_Called',
        properties: { 
            tenant: 'customerA',
            userAgent: req.get('User-Agent'),
            endpoint: '/api/claims'
        }
    });
    
    // Simulate some processing time
    setTimeout(() => {
        const duration = Date.now() - startTime;
        
        client.trackMetric({ name: 'Claims_API_Duration', value: duration, properties: { tenant: 'customerA' } });
        client.trackMetric({ name: 'Claims_Count', value: claims.length, properties: { tenant: 'customerA' } });
        
        client.trackDependency({ 
            target: 'claims-database', 
            name: 'query_claims', 
            data: 'SELECT * FROM claims', 
            duration: duration, 
            resultCode: 200, 
            success: true,
            properties: { tenant: 'customerA' }
        });
        
        res.json({
            success: true,
            count: claims.length,
            data: claims,
            timestamp: new Date().toISOString()
        });
    }, Math.random() * 100);
});

app.get('/error', (req, res) => {
    client.trackEvent({ name: 'Error_Endpoint_Called', properties: { tenant: 'customerA' } });
    
    const errorTypes = ['policy_lookup_failed', 'fraud_api_timeout', 'database_connection', 'payment_processing', 'document_storage'];
    const errorType = errorTypes[Math.floor(Math.random() * errorTypes.length)];
    
    const error = new Error(`Simulated ${errorType} for claim processing`);
    error.code = `CLAIMS_${errorType.toUpperCase()}`;
    
    client.trackException({ 
        exception: error,
        properties: {
            tenant: 'customerA',
            errorType: errorType,
            endpoint: '/error',
            domain: 'claims-processing',
            userAgent: req.get('User-Agent')
        }
    });
    
    client.trackMetric({ name: 'Claim_Processing_Error_Count', value: 1, properties: { errorType: errorType, tenant: 'customerA' } });
    
    res.status(500).json({
        error: true,
        message: error.message,
        code: error.code,
        tenant: 'customerA',
        timestamp: new Date().toISOString()
    });
});

app.get('/load', (req, res) => {
    const iterations = parseInt(req.query.iterations) || 1000;
    const startTime = Date.now();
    
    client.trackEvent({ 
        name: 'Load_Test_Started',
        properties: { tenant: 'customerA', iterations: iterations.toString() }
    });
    
    // Simulate CPU load
    let result = 0;
    for (let i = 0; i < iterations; i++) {
        result += Math.sqrt(i) * Math.random();
    }
    
    const duration = Date.now() - startTime;
    
    client.trackMetric({ name: 'Load_Test_Duration', value: duration, properties: { tenant: 'customerA' } });
    client.trackMetric({ name: 'Load_Test_Iterations', value: iterations, properties: { tenant: 'customerA' } });
    client.trackMetric({ name: 'CPU_Load_Result', value: result, properties: { tenant: 'customerA' } });
    
    client.trackDependency({ 
        target: 'cpu', 
        name: 'heavy_computation', 
        data: `${iterations} iterations`, 
        duration: duration, 
        resultCode: 200, 
        success: true,
        properties: { tenant: 'customerA' }
    });
    
    res.json({
        message: 'Load test completed',
        iterations: iterations,
        duration: duration,
        result: result,
        timestamp: new Date().toISOString()
    });
});

app.get('/memory', (req, res) => {
    const startTime = Date.now();
    
    client.trackEvent({ name: 'Memory_Test_Started', properties: { tenant: 'customerA' } });
    
    // Get memory usage before
    const memBefore = process.memoryUsage();
    
    // Allocate some memory
    const size = parseInt(req.query.size) || 1000000;
    const data = new Array(size).fill('memory test data');
    
    // Get memory usage after
    const memAfter = process.memoryUsage();
    const duration = Date.now() - startTime;
    
    client.trackMetric({ name: 'Memory_Test_Duration', value: duration, properties: { tenant: 'customerA' } });
    client.trackMetric({ name: 'Memory_Heap_Used', value: memAfter.heapUsed, properties: { tenant: 'customerA' } });
    client.trackMetric({ name: 'Memory_Heap_Total', value: memAfter.heapTotal, properties: { tenant: 'customerA' } });
    client.trackMetric({ name: 'Memory_External', value: memAfter.external, properties: { tenant: 'customerA' } });
    client.trackMetric({ name: 'Memory_RSS', value: memAfter.rss, properties: { tenant: 'customerA' } });
    
    res.json({
        message: 'Memory test completed',
        allocatedSize: size,
        duration: duration,
        memoryBefore: memBefore,
        memoryAfter: memAfter,
        memoryDifference: {
            heapUsed: memAfter.heapUsed - memBefore.heapUsed,
            heapTotal: memAfter.heapTotal - memBefore.heapTotal,
            external: memAfter.external - memBefore.external,
            rss: memAfter.rss - memBefore.rss
        },
        timestamp: new Date().toISOString()
    });
});

app.get('/dependencies', (req, res) => {
    const startTime = Date.now();
    
    client.trackEvent({ name: 'Dependencies_Test_Started' });
    
    // Simulate multiple dependency calls
    const dependencies = [
        { name: 'Azure SQL Database', duration: Math.random() * 50 + 10 },
        { name: 'Azure Storage', duration: Math.random() * 30 + 5 },
        { name: 'External API', duration: Math.random() * 100 + 20 },
        { name: 'Redis Cache', duration: Math.random() * 10 + 2 }
    ];
    
    dependencies.forEach(dep => {
        client.trackDependency({
            target: dep.name.toLowerCase().replace(/\s+/g, '_'),
            name: dep.name,
            data: 'test operation',
            duration: dep.duration,
            resultCode: 200,
            success: true
        });
        
        client.trackMetric({ 
            name: `Dependency_${dep.name.replace(/\s+/g, '_')}_Duration`, 
            value: dep.duration 
        });
    });
    
    const totalDuration = Date.now() - startTime;
    client.trackMetric({ name: 'Dependencies_Test_Total_Duration', value: totalDuration });
    
    res.json({
        message: 'Dependencies test completed',
        dependencies: dependencies,
        totalDuration: totalDuration,
        timestamp: new Date().toISOString()
    });
});

// Insurance-specific endpoints

// Submit a new claim
app.post('/api/submit-claim', (req, res) => {
    const startTime = Date.now();
    const claimId = claims.length + 1;
    const policyNumber = `POL-2024-${String(claimId).padStart(3, '0')}`;
    const claimAmount = Math.floor(Math.random() * 20000) + 1000;
    
    client.trackEvent({
        name: 'Claim_Submitted',
        properties: {
            tenant: 'customerA',
            claimId: claimId.toString(),
            policyNumber: policyNumber,
            claimType: 'Auto'
        }
    });
    
    client.trackMetric({
        name: 'Claim_Submission_Amount',
        value: claimAmount,
        properties: { tenant: 'customerA', policyNumber: policyNumber }
    });
    
    // Simulate processing delay
    setTimeout(() => {
        const duration = Date.now() - startTime;
        
        client.trackMetric({
            name: 'Claim_Processing_Duration',
            value: duration,
            properties: { tenant: 'customerA' }
        });
        
        const newClaim = {
            id: claimId,
            policyNumber: policyNumber,
            claimType: 'Auto',
            amount: claimAmount,
            status: 'pending',
            submittedDate: new Date().toISOString().split('T')[0]
        };
        
        claims.push(newClaim);
        
        res.status(201).json({
            success: true,
            claim: newClaim,
            processingTimeMs: duration,
            timestamp: new Date().toISOString()
        });
    }, 100 + Math.random() * 200);
});

// Fraud detection check
app.get('/fraud-check', (req, res) => {
    const startTime = Date.now();
    const claimId = parseInt(req.query.claimId) || Math.floor(Math.random() * claims.length) + 1;
    const claim = claims.find(c => c.id === claimId);
    
    if (!claim) {
        client.trackEvent({
            name: 'Fraud_Check_Failed',
            properties: { tenant: 'customerA', claimId: claimId.toString(), reason: 'claim_not_found' }
        });
        return res.status(404).json({ error: true, message: 'Claim not found' });
    }
    
    client.trackEvent({
        name: 'Fraud_Check_Started',
        properties: { tenant: 'customerA', claimId: claimId.toString() }
    });
    
    // Simulate fraud detection model processing
    setTimeout(() => {
        const duration = Date.now() - startTime;
        
        // Randomly flag some claims as suspicious
        const fraudRiskScore = Math.random();
        const isSuspicious = fraudRiskScore > 0.7;
        
        if (isSuspicious) {
            client.trackEvent({
                name: 'Fraud_Flag_Raised',
                properties: {
                    tenant: 'customerA',
                    claimId: claimId.toString(),
                    riskScore: fraudRiskScore.toString()
                }
            });
        }
        
        client.trackMetric({
            name: 'Fraud_Detection_Latency',
            value: duration,
            properties: { tenant: 'customerA', fraudDetected: isSuspicious.toString() }
        });
        
        client.trackMetric({
            name: 'Fraud_Risk_Score',
            value: fraudRiskScore,
            properties: { tenant: 'customerA', claimId: claimId.toString() }
        });
        
        res.json({
            claimId: claimId,
            fraudRiskScore: (fraudRiskScore * 100).toFixed(2),
            isSuspicious: isSuspicious,
            processingTimeMs: duration,
            recommendation: isSuspicious ? 'Manual Review Required' : 'Auto Approve',
            timestamp: new Date().toISOString()
        });
    }, 50 + Math.random() * 150);
});

// Error handling middleware
app.use((err, req, res, next) => {
    client.trackException({ 
        exception: err,
        properties: {
            tenant: 'customerA',
            url: req.url,
            method: req.method,
            userAgent: req.get('User-Agent')
        }
    });
    
    res.status(500).json({
        error: true,
        message: 'Internal server error',
        timestamp: new Date().toISOString()
    });
});

// 404 handler
app.use((req, res) => {
    client.trackEvent({ 
        name: '404_Not_Found',
        properties: {
            tenant: 'customerA',
            url: req.url,
            method: req.method,
            userAgent: req.get('User-Agent')
        }
    });
    
    res.status(404).json({
        error: true,
        message: 'Resource not found',
        url: req.url,
        timestamp: new Date().toISOString()
    });
});

app.listen(port, () => {
    console.log(`Server running on port ${port}`);
    
    client.trackEvent({ 
        name: 'Application_Started',
        properties: {
            tenant: 'customerA',
            domain: 'insurance-claims',
            port: port.toString(),
            environment: process.env.NODE_ENV || 'development',
            nodeVersion: process.version
        }
    });
    
    client.trackMetric({ name: 'Application_Startup_Time', value: Date.now() });
});

// Graceful shutdown
process.on('SIGTERM', () => {
    client.trackEvent({ name: 'Application_Shutdown', properties: { tenant: 'customerA' } });
    client.flush();
});

process.on('SIGINT', () => {
    client.trackEvent({ name: 'Application_Shutdown', properties: { tenant: 'customerA' } });
    client.flush();
    process.exit(0);
});
