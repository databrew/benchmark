# Create main dictionary for associating competencies with tabs
competency_dict <- 
  bind_rows(
    data_frame(tab_name = 'Strategy and Execution',
               competency = c('vision',
                              'strategy_formulation',
                              'management_committment',
                              'execution_capability')),
    data_frame(tab_name = 'Organization and Governance',
               competency = c('culture', 'people', 'structure', 'hr_function', 'governance')),
    data_frame(tab_name = 'Partnerships',
               competency = c('fintechs', 'bigtechs', 'regtechs', 'maturity_of_ecosystem_partners')),
    data_frame(tab_name = 'Products',
               competency = c('customer_journey', 'range_of_products', 'product_pricing', 'product_development_and_open_innovation')),
    data_frame(tab_name = 'Marketing',
               competency = c('customer_insights', 'communications', 'marketing_maturity')),
    data_frame(tab_name = 'Distribution and Channels',
               competency = c('strategy_and_organisation', 'physical_network', 'apps_webs_and_agents', 'sales_function')),
    data_frame(tab_name = 'Risk Management',
               competency = c('management_and_organisation', 'regulatory_compliance', 'kyc_aml_maturity_model', 'fraud_management_capability')),
    data_frame(tab_name = 'IT and MIS',
               competency = c('it_and_mis_strategy', 'hardware_architecture', 'software_architecture', 'it_security', 'reporting_and_analysis')),
    data_frame(tab_name = 'Operations and Customer Service',
               competency = c('customer_perfromance', 'agile_processes', 'process_automation', 'financial_controlling')),
    data_frame(tab_name = 'Responsible Finance',
               competency = c('consumer_protection_strategy', 'responsible_pricing_and_transparency', 'complaint_resolution', 'data_protection', 'financial_education'))
  )
competency_dict$tab_name <- tolower(gsub(' ', '_', competency_dict$tab_name))
tab_names <- unique(competency_dict$tab_name)
competency_dict$combined_name <- paste0(competency_dict$tab_name, '_', competency_dict$competency)
  
# Create dictionary for placing text
ui_dict <- 
  bind_rows(data_frame(name = c('strategy_and_execution_vision_1'),
                       text = c(paste0("There are diverse perspectives about what a digital bank means ",
                                       "reflecting a lack of alignment and common vision about where the business needs to go. ",
                                       "This often results in piecemeal initiatives or misguided efforts that lead to missed opportunities",
                                       ", sluggish performance and false starts of the digitak bank"))),
            data_frame(name = 'strategy_and_execution_vision_2',
                       text = 'Bank leaders may have a clear and common understanding
of exactly what digital means to them and, as a result, what it means to their business and articulated in any position document but it is somewhat theoretical and not translated into an actionable plan for implementation'),
            data_frame(name = 'strategy_and_execution_vision_3',
                       text = 'Being digital is about using data to make better and faster decisions, devolving decision making to smaller teams, and developing much more iterative and rapid ways of doing things. 
Cross functional teams share the same rooms fostering creativity 
Thinking in a digital way is not limited to just a handful of functions. It incorporates a broad swath of how the bank operate, including creatively partnering with external companies to extend necessary capabilities. The bank\'s digital mind-set institutionalizes cross-functional collaboration, flattens hierarchies, and builds environments to encourage the generation of new ideas. Incentives and metrics are developed to support such decision-making agility.
                       The organizational culture is perceived as "agile": quick to mobilize, nimble, collaborative, easy to get things done, responsive, flow of information, quick decision making, empowered to act, resilient, learning from failures.
                       They are able to support the cultural shift.'),
            
            data_frame(name = 'strategy_and_execution_strategy_formulation_1',
                       text = 'The digital strategy is more "evolutionary" than "revolutionary", it focuses on a few areas of the existing business model, in particular: 
- Customer engagement: migrating to direct digital channels; the bank is providing a seamless online and offline channel experience.
- Ecosystem network engagement: extending the network of business partners developping limited new digital affiliate partnerships
-Employee engagement: providing employees with effective tools for collaboration 
The strategy is formalised around the points described. 
Top management counts with enough market intelligence to identify competitors, define a SWOT analysis and define business targets.'),
            data_frame(name = 'strategy_and_execution_strategy_formulation_2',
                       text = 'The digital strategy starts to become more "revolutionary", than evolutionary; it focuses on more areas of the existing business model on top of the ones described already in particular: 
- Customer engagement: Developing deeper customer understanding from multiple internal and external data sources. Using customer analytics for next-best offer proposition and enhanced customer profitability management. Creating multiple mechanisms for instantaneous collaboration and exchange with and between customers.
- Ecosystem network engagement:Creating cross-industry customer data sources often through loyalty schemes. Positioning third- party offers and services in extension to own services.
-Employee engagement: Implementing new intelligent communications platforms, developing
a continuous innovation capability. Introducing new mobile solutions for field workforce, providing remote working solutions.
-Automation and efficiency: Automating and simplifying front-end and back-end processes, extending customer self-servicing, automating customer servicing and order management. Introducing remote monitoring
and tracking solutions. 
- Content: Creating personalized interfaces, providing real-time and instantaneous interaction, providing configuration and collaboration functionalities. 
The strategy is formalised around the points described. Top management is able to articulate targets around broad areas described above'),
            data_frame(name = 'strategy_and_execution_strategy_formulation_3',
                       text = 'The digital strategy is truly "revolutionary". It focuses on a new business model to become a game changer in the financial industry, in particular besides the features described in "formative" and "emerging" digital strategies, the Bank also develops: 
- Customer communities:Identifying and empowering customer communities around common interests and needs. Leveraging crowd intelligence and power by enabling customers to communicate with each other and the bank.
- Creative service partners: Developing a platform approach (mostly open source) enabling service partners to develop and sell services and products. Extending the bank’s products and service portfolio through service partners creating a broader customer experience
and tie-in. 
-Information networks: Developing information networks based on internal and external data and content sources (including connected devices/IOT). Motivating customers to share information and intelligence creating win-win propositions
-Bridging "bricks and bits": Creating a seamless experience and offer between the physical and the digital world. Integrating hardware and software offerings to drive customer choice and purchase. Merging digital and physical into a hybrid experience.
The strategy is formalised around the points described. 
Top management can articulate targets around all areas describe micro-action plans for each of them'),
            data_frame(name = '',
                       text = ''),
            data_frame(name = '',
                       text = ''),
            data_frame(name = '',
                       text = ''),
            data_frame(name = '',
                       text = ''),
            data_frame(name = '',
                       text = ''),
            data_frame(name = '',
                       text = ''),
            data_frame(name = '',
                       text = ''),
            data_frame(name = '',
                       text = ''))
  
