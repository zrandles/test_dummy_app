# Golden Deployment - Rails Template

**The definitive template for all new Rails apps in the zac_ecosystem.**

This app demonstrates every reusable pattern, properly configured for deployment, and ready to clone for new projects.

## Purpose

1. **Template for New Apps** - Copy this app to start new projects with all fixes included
2. **Living Documentation** - See working examples of all our patterns
3. **Testing Ground** - Test gem upgrades and deployment changes here first
4. **Deployment Smoke Test** - Always deployed to verify infrastructure health

## Production URL

http://24.199.71.69/golden_deployment

## Quick Start - Creating New Apps

```bash
cd ~/zac_ecosystem/rails-deploy-tools
ruby new_rails_app.rb my_new_app

# This automatically:
# 1. Copies golden_deployment
# 2. Replaces app name throughout all configs
# 3. Generates new master.key
# 4. Initializes git repo
```

See full documentation in `docs/` folder.
