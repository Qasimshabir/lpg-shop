# Vercel Deployment Guide

## Prerequisites

1. **MongoDB Atlas Account** (Free tier available)
   - Sign up at: https://www.mongodb.com/cloud/atlas
   - Create a new cluster
   - Get your connection string

2. **Vercel Account** (Free tier available)
   - Sign up at: https://vercel.com

## Step 1: Setup MongoDB Atlas

1. Go to MongoDB Atlas: https://cloud.mongodb.com
2. Create a new project (e.g., "LPG Dealer Shop")
3. Build a cluster (choose FREE tier)
4. Create a database user:
   - Database Access → Add New Database User
   - Username: `lpgadmin`
   - Password: Generate a secure password
   - Database User Privileges: Read and write to any database
5. Whitelist all IPs:
   - Network Access → Add IP Address
   - Click "Allow Access from Anywhere" (0.0.0.0/0)
6. Get connection string:
   - Clusters → Connect → Connect your application
   - Copy the connection string
   - Replace `<password>` with your database user password
   - Replace `<dbname>` with `lpg_dealer_shop`

Example:
```
mongodb+srv://lpgadmin:YOUR_PASSWORD@cluster0.xxxxx.mongodb.net/lpg_dealer_shop?retryWrites=true&w=majority
```

## Step 2: Deploy to Vercel

### Option A: Using Vercel CLI

1. Install Vercel CLI:
```bash
npm install -g vercel
```

2. Login to Vercel:
```bash
vercel login
```

3. Deploy from server directory:
```bash
cd server
vercel
```

4. Follow the prompts:
   - Set up and deploy? **Y**
   - Which scope? Select your account
   - Link to existing project? **N**
   - Project name? **lpg-dealer-api**
   - Directory? **./server** (or just press Enter if already in server directory)
   - Override settings? **N**

5. Add environment variables:
```bash
vercel env add MONGO_URI
```
Paste your MongoDB Atlas connection string

```bash
vercel env add JWT_SECRET
```
Enter a long random string (at least 32 characters)

6. Deploy to production:
```bash
vercel --prod
```

### Option B: Using Vercel Dashboard

1. Go to https://vercel.com/dashboard
2. Click "Add New" → "Project"
3. Import your Git repository
4. Configure:
   - Framework Preset: **Other**
   - Root Directory: **server**
   - Build Command: (leave empty)
   - Output Directory: (leave empty)
5. Add Environment Variables:
   - `MONGO_URI`: Your MongoDB Atlas connection string
   - `JWT_SECRET`: A long random string
   - `NODE_ENV`: production
6. Click "Deploy"

## Step 3: Update Flutter App

After deployment, you'll get a URL like: `https://lpg-dealer-api.vercel.app`

Update the app configuration dialog to include this URL:

1. Open the app
2. Double-tap the gas station icon
3. Enter: `https://lpg-dealer-api.vercel.app`
4. Click "Test" to verify connection
5. Click "Save"

## Step 4: Test the Deployment

Test the health endpoint:
```
https://your-app.vercel.app/api/health
```

You should see:
```json
{
  "status": "OK",
  "message": "LPG Dealer Management API is running",
  "timestamp": "..."
}
```

## Step 5: Seed the Database (Optional)

If you need to seed the production database:

1. Update `server/seeders/databaseSeeder.js` to use environment variables
2. Run locally with production MongoDB URI:
```bash
MONGO_URI="your_atlas_connection_string" node seeders/databaseSeeder.js
```

## Important Notes

1. **Images are stored in MongoDB** - No file system storage needed
2. **Logs** - Vercel has its own logging system (check Vercel dashboard)
3. **Cold Starts** - Free tier may have cold starts (first request takes longer)
4. **Rate Limiting** - Consider adjusting rate limits for production
5. **CORS** - Update CORS settings if needed for your domain

## Troubleshooting

### Deployment fails
- Check Vercel logs in dashboard
- Verify all environment variables are set
- Ensure MongoDB Atlas IP whitelist includes 0.0.0.0/0

### 500 Internal Server Error
1. Check Vercel Function Logs:
   - Go to Vercel Dashboard → Your Project → Logs
   - Look for error messages

2. Common issues:
   - **Missing MONGO_URI**: Add it in Vercel environment variables
   - **Missing JWT_SECRET**: Add it in Vercel environment variables
   - **MongoDB connection failed**: Check Atlas connection string and network access

3. Verify environment variables:
```bash
vercel env ls
```

4. Pull environment variables locally to test:
```bash
vercel env pull
```

### Can't connect to database
- Verify MongoDB connection string format:
  ```
  mongodb+srv://username:password@cluster.mongodb.net/lpg_dealer_shop?retryWrites=true&w=majority
  ```
- Check database user credentials
- Ensure network access is configured (0.0.0.0/0)
- Test connection locally with the same connection string

### Images not loading
- Images are now served from `/api/images/:id`
- Check MongoDB for Image collection
- Verify image data is being saved correctly
- Check browser console for CORS errors

### Function timeout
- Vercel free tier has 10-second timeout
- Check if MongoDB queries are optimized
- Consider upgrading Vercel plan if needed

## Environment Variables Reference

Required environment variables for Vercel:

```
MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/lpg_dealer_shop
JWT_SECRET=your_very_long_and_random_secret_key_here
NODE_ENV=production
```

## Updating the Deployment

To update your deployment:

```bash
cd server
vercel --prod
```

Or push to your Git repository if using Git integration.
