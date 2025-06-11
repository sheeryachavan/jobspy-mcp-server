import logger from '../logger.js';
import { searchParams } from '../schemas/searchParamsSchema.js';
import { execSync } from 'node:child_process';
import { z } from 'zod';
import changeCase from 'change-case-object';
import path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const PROJECT_ROOT = path.resolve(__dirname, '../..');
const JOBSPY_DIR = path.join(PROJECT_ROOT, 'jobspy');
const VENV_DIR = path.join(PROJECT_ROOT, 'venv');

/**
 * @typedef {Object} JobSearchParams
 * @property {string} [siteNames] - Names of job sites to search (linkedin, zip_recruiter, indeed, glassdoor, google, bayt)
 * @property {string} [searchTerm] - Term to search for
 * @property {string} [location] - Job location
 * @property {number} [distance] - Distance in miles, default 50
 * @property {string} [jobType] - Type of job: fulltime, parttime, internship, contract
 * @property {string} [googleSearchTerm] - Term for Google job search
 * @property {number} [resultsWanted] - Number of job results to retrieve for each site
 * @property {boolean} [easyApply] - Filters for jobs that are hosted on the job board site
 * @property {string} [descriptionFormat] - Format type of the job descriptions: markdown, html
 * @property {number} [offset] - Starts the search from an offset
 * @property {number} [hoursOld] - Filter jobs by the number of hours since posted
 * @property {number} [verbose] - Controls verbosity (0=errors only, 1=errors+warnings, 2=all logs)
 * @property {string} [countryIndeed] - Country code for Indeed search
 * @property {boolean} [isRemote] - Whether to search for remote jobs only
 * @property {boolean} [linkedinFetchDescription] - Whether to fetch LinkedIn job descriptions
 * @property {string} [linkedinCompanyIds] - Searches for linkedin jobs with specific company ids
 * @property {boolean} [enforceAnnualSalary] - Converts wages to annual salary
 * @property {string} [proxies] - Comma-separated list of proxies
 * @property {string} [caCert] - Path to CA Certificate file for proxies
 * @property {'json'|'csv'} [format] - Output format: JSON or CSV
 * @property {number} [timeout] - Timeout in milliseconds for the job search process
 */

export const searchJobsTool = (server, sseManager) =>
  server.tool(
    'search_jobs',
    'Search for jobs across various job listing websites',
    searchParams,
    async (params, extra) => {
      let progressInterval;
      try {
        logger.info('Received search_jobs request', { params, extra });

        // Track progress for SSE clients
        if (extra.sessionId && sseManager.hasConnection(extra.sessionId)) {
          let progress = 0;
          progressInterval = setInterval(() => {
            progress += 5;
            if (progress > 90) {
              progress = 90; // Cap at 90% until complete
            }

            // Send progress to all connected clients
            sseManager.notificationProgress(
              {
                type: 'progress',
                tool: 'search_jobs',
                progress,
                message: `Searching for jobs (${progress}%)...`,
              },
              extra.sessionId
            );
          }, 2000);
        }

        // Execute job search
        const result = await searchJobsHandler(params);

        // Clean up progress interval
        if (progressInterval) {
          clearInterval(progressInterval);

          // Send 100% progress update to all connected clients
          if (extra.sessionId && sseManager.hasConnection(extra.sessionId)) {
            sseManager.notificationProgress(
              {
                type: 'progress',
                tool: 'search_jobs',
                progress: 100,
                message: 'Job search completed',
              },
              extra.sessionId
            );
          }
        }

        return {
          isError: false,
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      } catch (error) {
        if (progressInterval) {
          clearInterval(progressInterval);
        }
        logger.error('Error in search_jobs handler', { error: error.message });
        return {
          isError: true,
          error: {
            message: error.message,
            code: 'INTERNAL_SERVER_ERROR',
          },
        };
      }
    }
  );

/**
 * Convert a date string to ISO 8601 format
 * Handles various input formats and normalizes them
 * @param {string|number|null} dateStr - The date string to convert
 * @returns {string|null} - ISO 8601 formatted date string or null if invalid
 */
function convertToISODate(dateStr) {
  if (!dateStr) return null;

  try {
    // If dateStr is a timestamp (number or numeric string)
    if (!isNaN(dateStr)) {
      // Check if it's milliseconds (13 digits) or seconds (10 digits)
      const timestamp =
        String(dateStr).length > 10 ? Number(dateStr) : Number(dateStr) * 1000;
      return new Date(timestamp).toISOString();
    }

    // Otherwise try to parse as date string
    const date = new Date(dateStr);
    if (!isNaN(date.getTime())) {
      return date.toISOString();
    }

    // If we couldn't parse it, return the original string
    logger.warn(`Could not parse date: ${dateStr}`);
    return dateStr;
  } catch (error) {
    logger.warn(`Error converting date: ${dateStr}`, { error: error.message });
    return dateStr;
  }
}

/**
 * Handler for the search_jobs MCP tool
 * @param {JobSearchParams} params - Search parameters
 * @returns {Promise<object>} Search results
 */
export async function searchJobsHandler(params) {
  let result;
  try {
    logger.info('Starting job search with parameters', { params });

    // Clean params by removing empty strings and 0 values
    const cleanedParams = {};
    for (const [key, value] of Object.entries(params)) {
      // Skip null, undefined, empty strings, and 0 values
      if (
        value === null ||
        value === undefined ||
        value === '' ||
        value === 0
      ) {
        continue;
      }
      cleanedParams[key] = value;
    }

    logger.info('Cleaned parameters', { cleanedParams });

    const validatedParams = z.object(searchParams).parse(cleanedParams);

    logger.info('Validated parameters', { validatedParams });

    // Check if Python and JobSpy are available
    try {
      execSync('python3 --version', { stdio: 'pipe' });
    } catch (error) {
      try {
        execSync('python --version', { stdio: 'pipe' });
      } catch (error2) {
        throw new Error('Python not found. Please install Python 3.x');
      }
    }

    // Check if jobspy directory exists
    try {
      if (!fs.existsSync(JOBSPY_DIR)) {
        throw new Error(`JobSpy directory not found at ${JOBSPY_DIR}`);
      }
      if (!fs.existsSync(path.join(JOBSPY_DIR, 'main.py'))) {
        throw new Error(`main.py not found in ${JOBSPY_DIR}`);
      }
    } catch (error) {
      if (error.message.includes('JobSpy directory') || error.message.includes('main.py')) {
        throw error;
      }
      throw new Error('File system check failed');
    }

    const args = buildCommandArgs(validatedParams);
    const pythonCmd = getPythonCommand();
    const cmd = `${pythonCmd} main.py ${args.join(' ')}`;
    logger.info(`Spawning process with command: ${cmd}`);
    logger.info(`Working directory: ${JOBSPY_DIR}`);

    const timeout = params.timeout || 60000; // Default timeout of 60 seconds
    result = execSync(cmd, { timeout, cwd: JOBSPY_DIR }).toString();

    const parsedData = JSON.parse(result);

    // Convert to camelCase and normalize date fields to ISO 8601
    const data = parsedData.map((job) => {
      const jobCamelCase = changeCase.camelCase(job);

      // Convert date fields to ISO 8601
      if (jobCamelCase.datePosted) {
        jobCamelCase.datePosted = convertToISODate(jobCamelCase.datePosted);
      }

      return jobCamelCase;
    });

    logger.info(`Found jobs: ${data.length}`);
    return {
      count: data.length || 0,
      message: 'Job search completed successfully',
      jobs: data || [],
    };
  } catch (error) {
    logger.error('Error in searchJobsHandler', {
      error: error.message,
      result,
    });
    throw error;
  }
}

/**
 * Get the appropriate Python command, preferring virtual environment
 * @returns {string} Python command
 */
function getPythonCommand() {
  
  // Check if virtual environment exists
  const venvPython = path.join(VENV_DIR, 'bin', 'python');
  const venvPython3 = path.join(VENV_DIR, 'bin', 'python3');
  
  if (fs.existsSync(venvPython3)) {
    return venvPython3;
  }
  if (fs.existsSync(venvPython)) {
    return venvPython;
  }
  
  // Fall back to system Python
  try {
    execSync('python3 --version', { stdio: 'pipe' });
    return 'python3';
  } catch (error) {
    try {
      execSync('python --version', { stdio: 'pipe' });
      return 'python';
    } catch (error2) {
      throw new Error('Python not found. Please install Python 3.x or run setup-local.sh');
    }
  }
}

/**
 * Build command arguments from parameters
 * @param {JobSearchParams} params - Search parameters
 * @returns {string[]} Command line arguments
 */
function buildCommandArgs(params) {
  const args = [];

  // Add each parameter as a command line argument
  if (params.siteNames) {
    args.push('--site_name', `"${params.siteNames}"`);
  }
  if (params.searchTerm) {
    args.push('--search_term', `"${params.searchTerm}"`);
  }
  if (params.location) {
    args.push('--location', `"${params.location}"`);
  }
  if (params.distance) {
    args.push('--distance', `${params.distance}`);
  }
  if (params.jobType) {
    args.push('--job_type', `${params.jobType}`);
  }
  if (params.googleSearchTerm) {
    args.push('--google_search_term', `"${params.googleSearchTerm}"`);
  }
  if (params.resultsWanted) {
    args.push('--results_wanted', `${params.resultsWanted}`);
  }
  if (params.easyApply) {
    args.push('--easy_apply');
  }
  if (params.descriptionFormat) {
    args.push('--description_format', `${params.descriptionFormat}`);
  }
  if (params.offset) {
    args.push('--offset', `${params.offset}`);
  }
  if (params.hoursOld) {
    args.push('--hours_old', `${params.hoursOld}`);
  }
  if (params.verbose !== undefined) {
    args.push('--verbose', `${params.verbose}`);
  }
  if (params.countryIndeed) {
    args.push('--country_indeed', `"${params.countryIndeed}"`);
  }
  if (params.isRemote) {
    args.push('--is_remote');
  }
  if (params.linkedinFetchDescription) {
    args.push('--linkedin_fetch_description');
  }
  if (params.linkedinCompanyIds) {
    args.push('--linkedin_company_ids', `"${params.linkedinCompanyIds}"`);
  }
  if (params.enforceAnnualSalary) {
    args.push('--enforce_annual_salary');
  }
  if (params.proxies) {
    args.push('--proxies', `"${params.proxies}"`);
  }
  if (params.caCert) {
    args.push('--ca_cert', `"${params.caCert}"`);
  }
  args.push('--format', params.format || 'json');
  return args;
}
