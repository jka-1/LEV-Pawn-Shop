// src/pages/RunnerDashboard.tsx
import React from "react";
import NavBar from "../components/NavBar";

export default function RunnerDashboard() {
  const handleStartShift = () => {
    console.log("Start Shift clicked");
  };

  const handleNavigateToMeetup = () => {
    console.log("Navigate to Meetup clicked");
  };

  const handleViewAssignments = () => {
    console.log("View Assignments clicked");
  };

  return (
    <div className="page page--runner">
      <NavBar />

      <main className="runner-main">
        <header className="runner-header">
          <h1 className="runner-title">Runner Dashboard</h1>
          <p className="runner-subtitle">
            Your current assignments and tools.
          </p>
        </header>

        <section className="runner-tools-card">
          <div className="runner-tools-header">
            <h2 className="runner-tools-title">Runner Tools</h2>
            <span className="runner-tools-dot" aria-hidden="true">
              •
            </span>
          </div>

          <ul className="runner-tools-list">
            <li className="runner-tool-row">
              <div className="runner-tool-icon" aria-hidden="true">
                🗺️
              </div>
              <div className="runner-tool-text">
                <div className="runner-tool-name">Start Live Navigation</div>
                <div className="runner-tool-desc">
                  Track your route and send location updates.
                </div>
              </div>
            </li>

          <li className="runner-tool-row">
              <div className="runner-tool-icon" aria-hidden="true">
                📦
              </div>
              <div className="runner-tool-text">
                <div className="runner-tool-name">Pickup Workflow</div>
                <div className="runner-tool-desc">
                  View pickup instructions for current orders.
                </div>
              </div>
            </li>

            <li className="runner-tool-row">
              <div className="runner-tool-icon" aria-hidden="true">
                🛡️
              </div>
              <div className="runner-tool-text">
                <div className="runner-tool-name">Item Verification</div>
                <div className="runner-tool-desc">
                  Confirm authenticity and validate items.
                </div>
              </div>
            </li>
          </ul>
        </section>

        <section className="runner-actions">
          <button
            type="button"
            className="runner-btn"
            onClick={handleStartShift}
          >
            <span className="runner-btn-icon" aria-hidden="true">
              🏃
            </span>
            <span>Start Shift</span>
          </button>

          <button
            type="button"
            className="runner-btn"
            onClick={handleNavigateToMeetup}
          >
            <span className="runner-btn-icon" aria-hidden="true">
              📍
            </span>
            <span>Navigate to Meetup</span>
          </button>

          <button
            type="button"
            className="runner-btn"
            onClick={handleViewAssignments}
          >
            <span className="runner-btn-icon" aria-hidden="true">
              📋
            </span>
            <span>View Assignments</span>
          </button>
        </section>

        <footer className="runner-footer">
          <span>Runnr • Powered by LEV</span>
        </footer>
      </main>
    </div>
  );
}
