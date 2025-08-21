import React, { useState, useEffect } from 'react';
import {
  Container, Typography, Table, TableBody, TableCell, TableContainer,
  TableHead, TableRow, Paper, Button, CircularProgress, Box, Alert
} from '@mui/material';

// !! CRUCIAL !! Replace this with your actual deployed API URL from `sam deploy`
const API_URL = "https://v8fvk59tw1.execute-api.ap-south-1.amazonaws.com/Prod/";

function App() {
  const [findings, setFindings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const fetchFindings = async () => {
    setLoading(true);
    try {
      const response = await fetch(`${API_URL}/findings`);
      if (!response.ok) throw new Error('Failed to fetch');
      const data = await response.json();
      setFindings(data);
    } catch (err) {
      setError('Could not connect to the API. Is the URL correct?');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchFindings();
  }, []);

  const handleAnalyze = async (findingId) => {
    const updatedFindings = findings.map(f => f.id === findingId ? { ...f, status: 'Analyzing' } : f);
    setFindings(updatedFindings);

    await fetch(`${API_URL}/findings/${findingId}/analyze`, { method: 'POST' });
    fetchFindings();
  };

  const handleDeploy = async (findingId) => {
    const updatedFindings = findings.map(f => f.id === findingId ? { ...f, status: 'Patching' } : f);
    setFindings(updatedFindings);

    await fetch(`${API_URL}/findings/${findingId}/deploy`, { method: 'POST' });
    setTimeout(fetchFindings, 2000); // Give a moment for status to update
  };

  const getStatusChip = (status) => {
    const colorMap = {
      'New': '#ff9800',
      'Analyzing': '#2196f3',
      'Analyzed': '#03a9f4',
      'Patching': '#f44336',
      'Patched': '#4caf50'
    };
    return (
      <Box
        component="span"
        sx={{
          bgcolor: colorMap[status] || 'grey',
          color: 'white',
          px: 1.5,
          py: 0.5,
          borderRadius: '12px',
          fontSize: '0.8rem'
        }}
      >
        {status}
      </Box>
    );
  };

  return (
    <Container maxWidth="lg" sx={{ mt: 4 }}>
      {/* Headline and Subtext */}
      <Typography variant="h3" gutterBottom component="h1" align="center">
        🛡️ AI-Powered Vulnerability Management for AWS
      </Typography>
      <Typography variant="h6" gutterBottom align="center" color="text.secondary" sx={{ mb: 4 }}>
        ⚡ Stay Ahead of Threats with <strong>Patch Pilot AI</strong>
      </Typography>

      {error && <Alert severity="error">{error}</Alert>}

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Vulnerability</TableCell>
              <TableCell>Instance ID</TableCell>
              <TableCell>Severity</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={5} align="center">
                  <CircularProgress />
                </TableCell>
              </TableRow>
            ) : (
              findings.map((finding) => (
                <React.Fragment key={finding.id}>
                  <TableRow>
                    <TableCell>{finding.title}</TableCell>
                    <TableCell>{finding.instanceId}</TableCell>
                    <TableCell>{finding.severity}</TableCell>
                    <TableCell>{getStatusChip(finding.status)}</TableCell>
                    <TableCell>
                      {finding.status === 'New' && (
                        <Button variant="contained" onClick={() => handleAnalyze(finding.id)}>
                          Analyze
                        </Button>
                      )}
                      {finding.status === 'Analyzed' && (
                        <Button
                          variant="contained"
                          color="secondary"
                          onClick={() => handleDeploy(finding.id)}
                        >
                          Deploy Fix
                        </Button>
                      )}
                      {['Analyzing', 'Patching'].includes(finding.status) && (
                        <CircularProgress size={24} />
                      )}
                    </TableCell>
                  </TableRow>
                  {finding.status === 'Analyzed' && (
                    <TableRow>
                      <TableCell colSpan={5} sx={{ p: 0 }}>
                        <Box sx={{ p: 2, bgcolor: '#f7f7f7' }}>
                          <Typography variant="h6">AI Analysis</Typography>
                          <Typography variant="body2" sx={{ mb: 1 }}>
                            <strong>Risk:</strong> {finding.riskSummary}
                          </Typography>
                          <Typography
                            variant="body2"
                            component="pre"
                            sx={{
                              bgcolor: '#eee',
                              p: 1,
                              borderRadius: 1,
                              fontFamily: 'monospace'
                            }}
                          >
                            <strong>Fix:</strong> {finding.suggestedFix}
                          </Typography>
                        </Box>
                      </TableCell>
                    </TableRow>
                  )}
                </React.Fragment>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>
    </Container>
  );
}

export default App;
