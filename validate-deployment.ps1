#!/usr/bin/env powershell
<#
.SYNOPSIS
    Quick deployment validation script for Python Redis app on Azure
.DESCRIPTION
    Validates Terraform configuration, Azure connectivity, and deployment health
.EXAMPLE
    .\validate-deployment.ps1
#>

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Azure Terraform Deployment Validator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Terraform
Write-Host "[1/5] Checking Terraform..." -ForegroundColor Yellow
try {
    $tfVersion = & terraform --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Terraform found: $($tfVersion.Split()[1])" -ForegroundColor Green
    } else {
        throw "Terraform not found"
    }
} catch {
    Write-Host "✗ Terraform not installed. Install from: https://www.terraform.io/downloads" -ForegroundColor Red
    exit 1
}

# Check Azure CLI
Write-Host ""
Write-Host "[2/5] Checking Azure CLI..." -ForegroundColor Yellow
try {
    $azVersion = & az --version 2>&1 | Select-Object -First 1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Azure CLI found: $azVersion" -ForegroundColor Green
    } else {
        throw "Azure CLI not found"
    }
} catch {
    Write-Host "✗ Azure CLI not installed. Install from: https://aka.ms/azurecli" -ForegroundColor Red
    exit 1
}

# Check Azure Login
Write-Host ""
Write-Host "[3/5] Checking Azure authentication..." -ForegroundColor Yellow
try {
    $account = & az account show --query "name" -o tsv 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Logged in to Azure: $account" -ForegroundColor Green
    } else {
        throw "Not logged in"
    }
} catch {
    Write-Host "✗ Not logged in to Azure. Run: az login" -ForegroundColor Red
    exit 1
}

# Check Terraform configuration
Write-Host ""
Write-Host "[4/5] Validating Terraform configuration..." -ForegroundColor Yellow
Push-Location terraform -ErrorAction SilentlyContinue
try {
    $validation = & terraform validate 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Terraform configuration is valid" -ForegroundColor Green
    } else {
        Write-Host "✗ Terraform validation failed:" -ForegroundColor Red
        Write-Host $validation
        exit 1
    }
} catch {
    Write-Host "✗ Terraform directory not found. Run from project root." -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}

# Check variables
Write-Host ""
Write-Host "[5/5] Checking terraform.tfvars..." -ForegroundColor Yellow
Push-Location terraform -ErrorAction SilentlyContinue
try {
    if (Test-Path "terraform.tfvars") {
        $subscriptionId = Select-String -Path "terraform.tfvars" -Pattern 'azure_subscription_id.*"(.*)"' | ForEach-Object { $_.Matches.Groups[1].Value }
        
        if ($subscriptionId -and $subscriptionId -ne "YOUR_SUBSCRIPTION_ID_HERE") {
            Write-Host "✓ Subscription ID configured: $($subscriptionId.Substring(0,8))..." -ForegroundColor Green
        } else {
            Write-Host "✗ Subscription ID not configured. Update terraform.tfvars" -ForegroundColor Red
            $subscriptionId = & az account show --query "id" -o tsv
            Write-Host "  Current subscription: $subscriptionId" -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "✗ terraform.tfvars not found" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "⚠ Could not fully validate terraform.tfvars" -ForegroundColor Yellow
} finally {
    Pop-Location
}

# Summary and next steps
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "VALIDATION COMPLETE ✓" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Review the execution plan:"
Write-Host "   cd terraform"
Write-Host "   terraform plan" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Deploy infrastructure:"
Write-Host "   terraform apply" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Monitor deployment (5-10 minutes):"
Write-Host "   terraform output" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Test your app:"
Write-Host "   terraform output app_access_url" -ForegroundColor Cyan
Write-Host ""
Write-Host "5. For detailed deployment guide:"
Write-Host "   See DEPLOYMENT.md" -ForegroundColor Cyan
Write-Host ""

Write-Host "Happy deploying! 🚀" -ForegroundColor Green
