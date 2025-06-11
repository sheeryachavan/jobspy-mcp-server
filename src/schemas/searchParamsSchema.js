import { z } from 'zod';

export const searchParams = {
  siteNames: z
    .union([
      z
        .string()
        .describe(
          'Comma-separated list of job sites to search. Options: indeed,linkedin,zip_recruiter,glassdoor,google,bayt,naukri'
        ),
      z
        .array(z.string())
        .describe(
          'Array of job sites to search. Options: indeed,linkedin,zip_recruiter,glassdoor,google,bayt,naukri'
        ),
    ])
    .transform((val) => {
      // If it's already a string, return it as is
      if (typeof val === 'string') {
        return val;
      }
      // If it's an array, join it with commas
      if (Array.isArray(val)) {
        return val.join(',');
      }
      return val;
    })
    .refine(
      (val) => {
        const sites = val.split(',').map((site) => site.trim());
        const validSites = [
          'indeed',
          'linkedin',
          'zip_recruiter',
          'glassdoor',
          'google',
          'bayt',
          'naukri',
        ];
        return sites.every((site) => validSites.includes(site));
      },
      {
        message:
          'Invalid site names. Allowed values: indeed, linkedin, zip_recruiter, glassdoor, google, bayt, naukri',
      }
    )
    .default('indeed'),
  searchTerm: z
    .string()
    .describe('Search term for jobs')
    .default('software engineer'),
  location: z.string().describe('Location for job search').default('remote'),
  distance: z
    .union([z.number(), z.string()])
    .transform((val) => {
      const num = typeof val === 'string' ? parseInt(val, 10) : val;
      return isNaN(num) ? 50 : num;
    })
    .default(50),
  jobType: z
    .enum(['fulltime', 'parttime', 'internship', 'contract'])
    .nullable()
    .describe('Type of job')
    .default(null),
  googleSearchTerm: z
    .string()
    .nullable()
    .describe('Google specific search term')
    .default(null),
  resultsWanted: z
    .union([z.number(), z.string()])
    .transform((val) => {
      const num = typeof val === 'string' ? parseInt(val, 10) : val;
      return isNaN(num) || num === 0 ? 20 : num;
    })
    .describe('Number of results wanted')
    .default(20),
  easyApply: z
    .boolean()
    .describe('Filter for jobs that are hosted on the job board site')
    .default(false),
  descriptionFormat: z
    .enum(['markdown', 'html'])
    .describe('Format type of the job descriptions')
    .default('markdown'),
  offset: z
    .union([z.number(), z.string()])
    .transform((val) => {
      const num = typeof val === 'string' ? parseInt(val, 10) : val;
      return isNaN(num) ? 0 : num;
    })
    .describe('Starts the search from an offset')
    .default(0),
  hoursOld: z
    .union([z.number(), z.string()])
    .transform((val) => {
      const num = typeof val === 'string' ? parseInt(val, 10) : val;
      return isNaN(num) || num === 0 ? 72 : num;
    })
    .describe('How many hours old the jobs can be')
    .default(72),
  verbose: z
    .union([z.number(), z.string()])
    .transform((val) => {
      const num = typeof val === 'string' ? parseInt(val, 10) : val;
      return isNaN(num) ? 2 : Math.max(0, Math.min(2, num));
    })
    .describe(
      'Controls verbosity (0=errors only, 1=errors+warnings, 2=all logs)'
    )
    .default(2),
  countryIndeed: z
    .string()
    .describe('Country for Indeed search')
    .default('USA'),
  isRemote: z
    .any()
    .describe(
      'Whether to search for remote jobs only. Accepts any truthy value.'
    )
    .transform((val) => {
      // Convert any truthy value to boolean
      if (typeof val === 'string') {
        // For strings, check for common "true" values
        return ['true', 'yes', '1', 'on', 'y'].includes(val.toLowerCase());
      }
      // For other types, use Boolean conversion
      return Boolean(val);
    })
    .default(false),
  linkedinFetchDescription: z
    .any()
    .describe(
      'Whether to fetch LinkedIn job descriptions (slower). Accepts any truthy value.'
    )
    .transform((val) => {
      // Convert any truthy value to boolean
      if (typeof val === 'string') {
        // For strings, check for common "true" values
        return ['true', 'yes', '1', 'on', 'y'].includes(val.toLowerCase());
      }
      // For other types, use Boolean conversion
      return Boolean(val);
    })
    .default(true),
  linkedinCompanyIds: z
    .union([
      z.string().describe('Comma-separated list of LinkedIn company IDs'),
      z.array(z.number()).describe('Array of LinkedIn company IDs'),
    ])
    .nullable()
    .transform((val) => {
      if (typeof val === 'string') {
        return val;
      }
      if (Array.isArray(val)) {
        return val.join(',');
      }
      return val;
    })
    .default(null),
  enforceAnnualSalary: z
    .boolean()
    .describe('Converts wages to annual salary')
    .default(false),
  proxies: z
    .union([
      z.string().describe('Comma-separated list of proxies'),
      z.array(z.string()).describe('Array of proxies'),
    ])
    .nullable()
    .transform((val) => {
      if (typeof val === 'string') {
        return val;
      }
      if (Array.isArray(val)) {
        return val.join(',');
      }
      return val;
    })
    .default(null),
  caCert: z
    .string()
    .nullable()
    .describe('Path to CA Certificate file for proxies')
    .default(null),
  format: z.enum(['json', 'csv']).describe('Output format').default('json'),
  timeout: z
    .union([z.number(), z.string()])
    .transform((val) => {
      const num = typeof val === 'string' ? parseInt(val, 10) : val;
      return isNaN(num) ? 120000 : num;
    })
    .describe('Timeout in milliseconds for the job search process')
    .default(120000),
};