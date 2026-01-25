import "./App.css";
import { useState, useEffect } from "react";

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL;
if (!API_BASE_URL) {
  console.error("VITE_API_BASE_URL is not defined");
}

function App() {
  const [appId, setAppId] = useState("");
  const [jobs, setJobs] = useState([]);

  const runHealthCheck = async () => {
    if (!appId) {
      alert("Please enter Application ID");
      return;
    }

    try {
      const response = await fetch(`${API_BASE_URL}/jobs?app_id=${appId}`, {
        method: "POST",
      });

      const data = await response.json();
      console.log("Job created:", data);
      // fetch updated job list
      fetchJobs();
    } catch (error) {
      console.error("Error running health check:", error);
    }
  };

  const fetchJobs = async () => {
    if (!appId) return;

    try {
      const response = await fetch(`${API_BASE_URL}/jobs?app_id=${appId}`);

      const data = await response.json();
      setJobs(data);
    } catch (error) {
      console.error("Error fetching jobs:", error);
    }
  };

  useEffect(() => {
    if (!appId) return;

    const interval = setInterval(() => {
      fetchJobs();
    }, 3000); // every 3 seconds

    return () => clearInterval(interval);
  }, [appId]);

  return (
    <div style={{ padding: "20px" }}>
      <h1>Infrastructure Health Portal</h1>

      <div style={{ marginTop: "20px" }}>
        <input
          type="text"
          placeholder="Enter Application ID"
          value={appId}
          onChange={(e) => setAppId(e.target.value)}
          style={{ padding: "8px", marginRight: "10px" }}
        />
        <button style={{ padding: "8px" }} onClick={runHealthCheck}>
          Run Health Check
        </button>
      </div>

      <div style={{ marginTop: "30px" }}>
        <h3>Health Check Jobs</h3>
        {jobs.length === 0 ? (
          <p>No jobs yet</p>
        ) : (
          <ul>
            {jobs.map((job) => (
              <li key={job.job_id}>
                {job.application_id} - {job.status}
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}

export default App;
