# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing data in development
Example.destroy_all if Rails.env.development?

puts "🌱 Seeding golden_deployment with example patterns..."

examples_data = [
  # UI Patterns
  {
    name: "Advanced Table Filtering",
    category: "ui_pattern",
    status: "completed",
    description: "Dual-handle slider filters with percentile calculations. Features: 3-state column visibility (hidden/shown/featured), filter vs elimination modes, localStorage persistence, real-time row count.",
    priority: 5,
    score: 95,
    complexity: 4,
    speed: 3,
    quality: 5
  },
  {
    name: "Status Badge Component",
    category: "ui_pattern",
    status: "completed",
    description: "Colored badge helper for status display. Supports: new (blue), in_progress (yellow), completed (green), archived (gray). Tailwind-based, consistent across apps.",
    priority: 5,
    score: 88,
    complexity: 1,
    speed: 5,
    quality: 5
  },
  {
    name: "Modal Configuration Panel",
    category: "ui_pattern",
    status: "completed",
    description: "Full-screen modal overlay for configuration. Includes: drag-and-drop column management, category grouping, save/cancel actions, Stimulus controller integration.",
    priority: 4,
    score: 82,
    complexity: 3,
    speed: 3,
    quality: 4
  },
  {
    name: "Dashboard Stats Grid",
    category: "ui_pattern",
    status: "completed",
    description: "Responsive grid of stat cards with icons and colors. Shows: total count, status breakdowns, percentages, trend indicators. Mobile-friendly.",
    priority: 4,
    score: 75,
    complexity: 2,
    speed: 4,
    quality: 4
  },
  {
    name: "Sortable Table Headers",
    category: "ui_pattern",
    status: "completed",
    description: "Click-to-sort table columns with visual indicators (↑/↓). Supports: numeric and text sorting, remembering sort state, multi-column fallback sorting.",
    priority: 3,
    score: 70,
    complexity: 2,
    speed: 4,
    quality: 4
  },
  {
    name: "Tabbed Navigation",
    category: "ui_pattern",
    status: "in_progress",
    description: "Horizontal tab navigation with active state. Clean Tailwind styling, mobile-responsive, supports icons and counts.",
    priority: 3,
    score: 65,
    complexity: 1,
    speed: 5,
    quality: 3
  },
  {
    name: "Toast Notifications",
    category: "ui_pattern",
    status: "new",
    description: "Non-blocking success/error messages. Auto-dismiss, stackable, accessible, Stimulus-powered.",
    priority: 2,
    score: 55,
    complexity: 2,
    speed: 3,
    quality: 3
  },
  {
    name: "Dropdown Menu Component",
    category: "ui_pattern",
    status: "new",
    description: "Accessible dropdown menus with keyboard navigation. Handles: click outside to close, arrow key navigation, escape to close.",
    priority: 2,
    score: 48,
    complexity: 3,
    speed: 3,
    quality: 3
  },
  {
    name: "Form Validation Feedback",
    category: "ui_pattern",
    status: "new",
    description: "Inline error messages with field highlighting. Real-time validation, clear error text, accessible labels.",
    priority: 3,
    score: 62,
    complexity: 2,
    speed: 3,
    quality: 4
  },
  {
    name: "Empty State Component",
    category: "ui_pattern",
    status: "new",
    description: "User-friendly empty state displays with calls-to-action. Includes: illustration/icon, helpful text, primary action button.",
    priority: 2,
    score: 42,
    complexity: 1,
    speed: 5,
    quality: 3
  },
  {
    name: "Loading Skeleton Screens",
    category: "ui_pattern",
    status: "new",
    description: "Animated placeholder content during loading. Better UX than spinners, reduces perceived wait time.",
    priority: 2,
    score: 38,
    complexity: 2,
    speed: 4,
    quality: 2
  },
  {
    name: "Responsive Data Tables",
    category: "ui_pattern",
    status: "in_progress",
    description: "Mobile-friendly table patterns. Cards on mobile, full table on desktop. Horizontal scroll fallback.",
    priority: 4,
    score: 71,
    complexity: 3,
    speed: 3,
    quality: 4
  },

  # Backend Patterns
  {
    name: "API Token Authentication",
    category: "backend_pattern",
    status: "completed",
    description: "Bearer token authentication for API endpoints. Uses Rails credentials or ENV vars. Secure comparison with ActiveSupport::SecurityUtils.",
    priority: 5,
    score: 92,
    complexity: 2,
    speed: 4,
    quality: 5
  },
  {
    name: "Bulk Upsert API Endpoint",
    category: "backend_pattern",
    status: "completed",
    description: "Transaction-based bulk create/update via API. Finds by unique key (e.g., name), updates if exists, creates if new. Returns created/updated counts.",
    priority: 5,
    score: 89,
    complexity: 3,
    speed: 4,
    quality: 5
  },
  {
    name: "Service Objects",
    category: "backend_pattern",
    status: "completed",
    description: "Business logic extraction pattern. Class methods for operations, clear interface, testable, keeps controllers thin.",
    priority: 5,
    score: 85,
    complexity: 2,
    speed: 4,
    quality: 5
  },
  {
    name: "Background Jobs with Solid Queue",
    category: "backend_pattern",
    status: "completed",
    description: "Rails 8 job processing. Recurring jobs via config/recurring.yml. No Redis/Sidekiq needed.",
    priority: 5,
    score: 88,
    complexity: 2,
    speed: 4,
    quality: 5
  },
  {
    name: "Percentile Calculations",
    category: "backend_pattern",
    status: "completed",
    description: "Statistical analysis for filtering. Calculates value at each 5th percentile (0, 5, 10, ..., 100) for numeric columns. Powers advanced table filters.",
    priority: 4,
    score: 78,
    complexity: 3,
    speed: 3,
    quality: 4
  },
  {
    name: "Enum-based Status Fields",
    category: "backend_pattern",
    status: "completed",
    description: "Simple status management with validations. No gems needed, just CONSTANTS array and validation. Includes helper methods (new?, completed?, etc.).",
    priority: 4,
    score: 82,
    complexity: 1,
    speed: 5,
    quality: 4
  },
  {
    name: "Model Calculated Attributes",
    category: "backend_pattern",
    status: "completed",
    description: "Computed fields as instance methods. Example: average_metrics calculates mean of multiple numeric fields. Keeps database simple.",
    priority: 3,
    score: 68,
    complexity: 1,
    speed: 5,
    quality: 3
  },
  {
    name: "Strong Parameters Pattern",
    category: "backend_pattern",
    status: "completed",
    description: "Rails security best practice. Private permit method in controller, explicitly allow fields, never permit all.",
    priority: 5,
    score: 90,
    complexity: 1,
    speed: 5,
    quality: 5
  },
  {
    name: "JSON API Responses",
    category: "backend_pattern",
    status: "completed",
    description: "Consistent JSON structure for APIs. Include: success boolean, counts, data arrays, error details. Clear and predictable.",
    priority: 4,
    score: 75,
    complexity: 1,
    speed: 5,
    quality: 4
  },
  {
    name: "Transaction Rollback on Errors",
    category: "backend_pattern",
    status: "completed",
    description: "All-or-nothing data operations. ActiveRecord::Base.transaction with rollback on any failure. Prevents partial updates.",
    priority: 5,
    score: 87,
    complexity: 2,
    speed: 4,
    quality: 5
  },
  {
    name: "Scopes for Common Queries",
    category: "backend_pattern",
    status: "in_progress",
    description: "Reusable query methods on models. Example: scope :completed, -> { where(status: 'completed') }. Chainable, readable.",
    priority: 3,
    score: 72,
    complexity: 1,
    speed: 5,
    quality: 4
  },
  {
    name: "Concerns for Shared Behavior",
    category: "backend_pattern",
    status: "new",
    description: "DRY up model/controller code with concerns. Example: Filterable, Sortable, Searchable concerns.",
    priority: 3,
    score: 64,
    complexity: 2,
    speed: 4,
    quality: 3
  },
  {
    name: "Caching Strategy",
    category: "backend_pattern",
    status: "new",
    description: "Rails.cache for expensive operations. Fragment caching for views, method caching for calculations. Clear when data changes.",
    priority: 3,
    score: 58,
    complexity: 3,
    speed: 3,
    quality: 3
  },
  {
    name: "N+1 Query Prevention",
    category: "backend_pattern",
    status: "in_progress",
    description: "Use includes/preload to avoid N+1 queries. Bullet gem in development for detection.",
    priority: 4,
    score: 76,
    complexity: 2,
    speed: 4,
    quality: 4
  },

  # Data Patterns
  {
    name: "Seed File Pattern",
    category: "data_pattern",
    status: "completed",
    description: "Idempotent seed data creation. Use find_or_create_by for safety, clear existing in development, production-safe.",
    priority: 5,
    score: 86,
    complexity: 1,
    speed: 5,
    quality: 5
  },
  {
    name: "Migration Best Practices",
    category: "data_pattern",
    status: "completed",
    description: "Safe, reversible database changes. Add indexes for foreign keys, use change (not up/down), test rollback.",
    priority: 5,
    score: 91,
    complexity: 2,
    speed: 4,
    quality: 5
  },
  {
    name: "Database Constraints",
    category: "data_pattern",
    status: "completed",
    description: "Data integrity at DB level. NOT NULL constraints, unique indexes, foreign keys. Pairs with model validations.",
    priority: 4,
    score: 80,
    complexity: 2,
    speed: 4,
    quality: 4
  },
  {
    name: "Polymorphic Associations",
    category: "data_pattern",
    status: "in_progress",
    description: "Flexible belongs_to relationships. Example: Comment belongs_to :commentable (Post, Article, etc.). Requires type + id columns.",
    priority: 3,
    score: 67,
    complexity: 3,
    speed: 3,
    quality: 3
  },
  {
    name: "JSON Column Storage",
    category: "data_pattern",
    status: "new",
    description: "Flexible data in PostgreSQL/SQLite JSON columns. Good for: metadata, settings, array data. Queryable in PostgreSQL.",
    priority: 3,
    score: 61,
    complexity: 2,
    speed: 4,
    quality: 3
  },
  {
    name: "Soft Deletes",
    category: "data_pattern",
    status: "new",
    description: "deleted_at timestamp instead of hard delete. Query with default scope, recoverable, audit-friendly.",
    priority: 3,
    score: 56,
    complexity: 2,
    speed: 4,
    quality: 3
  },
  {
    name: "Audit Trail",
    category: "data_pattern",
    status: "new",
    description: "Track who changed what when. created_by, updated_by, timestamps. Optional: full versioning with paper_trail gem.",
    priority: 2,
    score: 44,
    complexity: 3,
    speed: 3,
    quality: 2
  },
  {
    name: "UUID Primary Keys",
    category: "data_pattern",
    status: "new",
    description: "Use UUIDs instead of auto-incrementing IDs. Better for: distributed systems, security (no sequential IDs), merging databases.",
    priority: 2,
    score: 39,
    complexity: 2,
    speed: 3,
    quality: 2
  },
  {
    name: "Counter Caches",
    category: "data_pattern",
    status: "new",
    description: "Denormalized count columns for performance. Example: posts_count on User. Updated automatically by Rails.",
    priority: 3,
    score: 63,
    complexity: 1,
    speed: 5,
    quality: 3
  },

  # Deployment Patterns
  {
    name: "Capistrano Deployment",
    category: "deployment_pattern",
    status: "completed",
    description: "Automated deployment with cap production deploy. Handles: git push, asset precompilation, migrations, service restart. Uses symlinks for zero-downtime.",
    priority: 5,
    score: 94,
    complexity: 3,
    speed: 4,
    quality: 5
  },
  {
    name: "Systemd Service Configuration",
    category: "deployment_pattern",
    status: "completed",
    description: "App runs as systemd service. Auto-restart on failure, log to journalctl, user permissions, environment variables.",
    priority: 5,
    score: 89,
    complexity: 3,
    speed: 3,
    quality: 5
  },
  {
    name: "Nginx Path-Based Routing",
    category: "deployment_pattern",
    status: "completed",
    description: "Multiple apps on one server via /app_name paths. Requires: relative_url_root in production.rb, route scoping, nginx upstream + location blocks.",
    priority: 5,
    score: 87,
    complexity: 4,
    speed: 3,
    quality: 4
  },
  {
    name: "Asset Precompilation Fix",
    category: "deployment_pattern",
    status: "completed",
    description: "CRITICAL: Remove clear_actions from deploy.rb. Ensures CSS/JS changes deploy. Verify with 'deploy:assets:precompile' in logs.",
    priority: 5,
    score: 93,
    complexity: 1,
    speed: 5,
    quality: 5
  },
  {
    name: "Puma Production Configuration",
    category: "deployment_pattern",
    status: "completed",
    description: "Unix socket for nginx communication. Correct shared paths, worker/thread tuning, preload_app for memory efficiency.",
    priority: 5,
    score: 85,
    complexity: 2,
    speed: 4,
    quality: 4
  },
  {
    name: "Environment Credentials Management",
    category: "deployment_pattern",
    status: "completed",
    description: "API tokens in Rails credentials or ENV vars. Never commit secrets. Use credentials:edit for encryption, deploy master.key separately.",
    priority: 5,
    score: 96,
    complexity: 2,
    speed: 4,
    quality: 5
  },
  {
    name: "Database Configuration",
    category: "deployment_pattern",
    status: "completed",
    description: "Production database in shared/ directory. Survives deployments. config/database.yml points to <%= ENV['RAILS_ENV'] %> paths.",
    priority: 5,
    score: 88,
    complexity: 2,
    speed: 4,
    quality: 5
  },
  {
    name: "Log Rotation",
    category: "deployment_pattern",
    status: "in_progress",
    description: "Prevent log files from filling disk. Use logrotate or Rails log rotation config. Compress old logs, delete after N days.",
    priority: 3,
    score: 69,
    complexity: 2,
    speed: 4,
    quality: 3
  },
  {
    name: "Health Check Endpoint",
    category: "deployment_pattern",
    status: "completed",
    description: "GET /up returns 200 if app is running. Used by: load balancers, monitoring, deployment verification. Built-in with Rails 8.",
    priority: 4,
    score: 77,
    complexity: 1,
    speed: 5,
    quality: 4
  },
  {
    name: "Deployment Verification Script",
    category: "deployment_pattern",
    status: "new",
    description: "Post-deploy smoke tests. Check: HTTP 200, database connectivity, background jobs running, key features work.",
    priority: 3,
    score: 59,
    complexity: 2,
    speed: 3,
    quality: 3
  },
  {
    name: "Rollback Strategy",
    category: "deployment_pattern",
    status: "new",
    description: "Quick recovery from bad deploys. cap production deploy:rollback, symlink to previous release, restart service. Keep last 5 releases.",
    priority: 4,
    score: 74,
    complexity: 2,
    speed: 4,
    quality: 4
  },
  {
    name: "Zero-Downtime Migrations",
    category: "deployment_pattern",
    status: "new",
    description: "Safe schema changes on live apps. Add columns (nullable first), then populate, then add constraint. Drop in separate deploy.",
    priority: 3,
    score: 65,
    complexity: 4,
    speed: 2,
    quality: 4
  },
  {
    name: "Monitoring and Alerting",
    category: "deployment_pattern",
    status: "in_progress",
    description: "Know when things break. app_monitor dashboard, systemd status, log aggregation, Slack/email alerts for errors.",
    priority: 4,
    score: 73,
    complexity: 3,
    speed: 3,
    quality: 4
  }
]

created_count = 0
examples_data.each do |data|
  Example.create!(data)
  created_count += 1
  print "."
end

puts "\n✅ Created #{created_count} example patterns"
puts "📊 Status breakdown:"
puts "   - New: #{Example.where(status: 'new').count}"
puts "   - In Progress: #{Example.where(status: 'in_progress').count}"
puts "   - Completed: #{Example.where(status: 'completed').count}"
puts "   - Archived: #{Example.where(status: 'archived').count}"
puts "📁 Category breakdown:"
puts "   - UI Patterns: #{Example.where(category: 'ui_pattern').count}"
puts "   - Backend Patterns: #{Example.where(category: 'backend_pattern').count}"
puts "   - Data Patterns: #{Example.where(category: 'data_pattern').count}"
puts "   - Deployment Patterns: #{Example.where(category: 'deployment_pattern').count}"
