# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

case Rails.env
when "development"
    # development seeds
    users = User.create([
        {email: "admin@admin.com", name: "ad min", password: "adminpassword", password_confirmation: "adminpassword", role: 99}, 
        {email: "intern@intern.com", name: "in tern", password: "intern", password_confirmation: "intern", role: 3},
        {email: "volunteer@volunteer.com", name: "volu nteer", password: "volunteer", password_confirmation: "volunteer", role: 2},
        {email: "organization@organization.com", name: "organi zation", password: "organization", password_confirmation: "organization", role: 1},
        {email: "guest@guest.com", name: "gu est", password: "guestpassword", password_confirmation: "guestpassword", role: 0},
    ])
when "production"
    # production seeds 
    # RAILS_ENV=production bin/rails db:seed
    users = User.create([
        {email: "admin@admin.com", name: "ad min", password: "changeme", password_confirmation: "changeme", role: 99}, 
    ])
end

metadata_types = MetadataType.create([
    {name: "Collection Type", order: 1, user_id: 1},
    {name: "Education Type", order: 1, user_id: 1},
    {name: "Primary User", order: 1, user_id: 1},
    {name: "Resource Type", order: 1, user_id: 1},
    {name: "Rights Statement", order: 1, user_id: 1},
    {name: "Subcategory", order: 1, user_id: 1},
    {name: "Subject", order: 1, user_id: 1},
    # {name: "", order: 1, user_id: 1},
])

def create_metadata(name, metadata_type, user_id)
    if Metadatum.find_by(name: name, metadata_type: metadata_type, user_id: user_id) == nil
        Metadatum.create(name: name, metadata_type: metadata_type, user_id: user_id)
    end
end

education_types = ["Lower Primary School Student","Upper Primary School Student","Middle School Student","Secondary School Student","College/Upper Division","Adult Education","Career/Technical","Graduate/Professional","Preschool","Kindergarten","Grade 01","Grade 02","Grade 03","Grade 04","Grade 05","Grade 06","Grade 07","Grade 08","Grade 09","Grade 10","Grade 11","Grade 12"]
education_types.each do |education_type|
    create_metadata(education_type, metadata_types.find {|metadata| metadata.name == "Education Type"}, 1)
end

collection_types = ["Arizona Crisis Response Collection","Rwanda Agricultural Collection","Latin America Educational Library","Peace Corps Collection","Namibia Educational Collection","Lesotho Educational Collection","Malawi Educational Collection","Malawi Health Collection","General Agricultural Library","General Health Library","General Educational Library","Middle East Educational Library","Northeast Syria Collection","Southern Africa Educational Collection","Mexico Educational Collection","Pacific Islands Educational Collection","East Africa Educational Collection","Arizona Health Collection","Community Health Collection"]
collection_types.each do |collection_type|
    create_metadata(collection_type, metadata_types.find {|metadata| metadata.name == "Collection Type"}, 1)
end

primary_users = ["Student","Instructor","Parent","Peace Corps Volunteer","Community Member","Field Extension Worker","Farmer"]
primary_users.each do |primary_user|
    create_metadata(primary_user, metadata_types.find {|metadata| metadata.name == "Primary User"}, 1)
end

resource_types = ["Activity","Video","Lesson Plan","Book","Fiction","Curriculum","Article","Fact Sheet","Textbook","Manual","Map","Report","Course","Syllabus","Lecture","Lecture Notes","Audiobook","Article","Student Guide","Case Study","Teaching Guide","كتاب مدرسي","Affiche","Fiche Descriptive","Livre","Activité","Histoire","Manuel","Prèsentation","Contrôle","Vidéo","Plan de Leçon","Manuel Scolaire","المنهج.الدراسي","قصة","كتيب/دليل","فعالية/نشاط","كتاب","الكتاب.المدرسي","فعالية/نشاط","منهج.دراسي","قصة","Infographic","منهج.دراسي","Podcast","Reference Guide","Hoja de Cálculo","Plan de Lección","Artículo","Libro","Reporto","Libro de Audio","Actividad","Mapa","فيديو","Articulo","Activdad","قصص القصيرة","ورقة عمل","Song","Infográfico","Poem","Guión","Igitabo","Amashusho","Inyangiko","Gahunda y’isomo","Urupapuro rw’amakurushingiro","Ishusho","Short Story","Storybook","Dataset"]
resource_types.each do |resource_type|
    create_metadata(resource_type, metadata_types.find {|metadata| metadata.name == "Resource Type"}, 1)
end

rights_statements = ["All rights reserved - permission granted to share on SolarSPELL library for educational purposes only.","Can be shared for educational purposes only.","Public domain.","CC BY - This license allows reusers to distribute, remix, adapt, and build upon the material in any medium or format, so long as attribution is given to the creator. The license allows for commercial use.","CC BY SA - This license allows reusers to distribute, remix, adapt, and build upon the material in any medium or format, so long as attribution is given to the creator. The license allows for commercial use. If you remix, adapt, or build upon the material, you must license the modified material under identical terms.","CC BY NC SA - This license allows reusers to distribute, remix, adapt, and build upon the material in any medium or format for noncommercial purposes only, and only so long as attribution is given to the creator. If you remix, adapt, or build upon the material, you must license the modified material under identical terms. ","CC BY NC - This license allows reusers to distribute, remix, adapt, and build upon the material in any medium or format for noncommercial purposes only, and only so long as attribution is given to the creator. ","CC BY ND - This license allows reusers to copy and distribute the material in any medium or format in unadapted form only, and only so long as attribution is given to the creator. The license allows for commercial use. ","CC BY NC ND - This license allows reusers to copy and distribute the material in any medium or format in unadapted form only, for noncommercial purposes only, and only so long as attribution is given to the creator."]
rights_statements.each do |rights_statement|
    create_metadata(rights_statement, metadata_types.find {|metadata| metadata.name == "Rights Statement"}, 1)
end

subcategories = ["Art Activities","Performing Arts","Music and Dance","Artists from Around the World","Art Styles","Art History","Principles of Art and Design","Peace Corps Resources","How to Use the SolarSPELL","Classroom Resources","Careers and School","SAT Preparation","Numbers and Counting","Addition and Subtraction","Algebra and Geometry","Decimals and Fractions","Multiplication and Division","Math Textbooks","Probability and Statistics","Measurement","Math Activities","Life Science","Physical Science","Environment","Science Textbooks","Earth Science","Science Experiments","Community Health","Safety and First Aid","Physical Activity","Food Safety and Sanitation","Teaching Resources","COVID-19","Disaster Preparedness","Different Abilities","Nutrition","Hygiene","History","Geography","Politics and Civics","Culture and Religion","Anthropology","Writing and Reading Comprehension","English Novels","Dictionaries and Thesauri","French Storybooks","Language Learning Resources","English Phonics","Engllish Grammar","English Early Readers","Creative Writing","Poetry","Digital Literacy Class Activities","Using Technology","Digital Citizenship for Students","Digital Literacy","Information Literacy","News Literacy","Climate Change","Sustainable Agriculture","Environmental Sustainability","Economic Sustainability","Social Sustainability","Culture of Care","Innovación Educativa","Phonics","Grammar","Fantasy","Short Stories","Fiction","Adventure","Science Fiction","Mystery","Biology","Chemistry","Biochemistry","Physics","Psychology","Cardiac System","Endocrine System","Epidemiology","Gastrointestinal System","General Physiology","Genetics","Genitourinary system","Hematology","Immune System","Integumentary System","Musculoskeletal System","Nervous System","Reproductive System","Respiratory System","Environmental Health","Preventative Health","Primary Care","Immunizations","Smoking and Drug Use","Violence","Population Change","Public Health","General Practice","Public Health Dentistry","Preventative Dentistry","Oral Surgery","Endodontics","Orthodontics","Oral Pathology","Pediatric Dentistry","Geriatric Dentistry","Periodontics","Clinical Decision Making","Computer-Assisted Diagnosis","Diagnostic Errors","Diagnostic Techniques and Procedures","Clinical Laboratory Techniques","Diagnostic Imaging","Electrodiagnosis","Physical Examinations","Symptom Assessment","First Aid","Resuscitation","Advanced Trauma","Wounds and Injuries","Communicable Diseases","Noncommunicable Diseases","Digestive System Surgical Procedures","Perioperative Care","Urogenital Surgical Procedures","Orthopedic Procedures","Thoracic Surgical Procedures","Psychology","Psychiatry","Mental Disorders","Mental Health Services","Child Health and Development","Adolescent Health and Development","Pediatrics Assessment","Congenital Abnormalities","Emergency Pediatric Medicine","Principles of Pharmacology","Pharmacokinetics","Pharmaceutical Preparations","Analgesia and Anesthesia","Research Methodology and Design","Health Protocols","Health Best Practices","Professional Health Guidelines","Health Policies","Statutes and Court Decisions","Quality Indicators in Healthcare","Family Planning and Contraception","Reproductive Health","Women's Empowerment","Health Promotion and Assessment","Diagnostic Tests","Pregnancy","Fetal Medicine","Labor and Delivery","Postpartum Care","Curriculum","Textbooks","Syllabi","Assessment Resources for Professors","Teaching Resources for Professors","Large Animal","Small Animal","Fisheries","Beekeeping","Vermiculture","Animal Care","Animal Housing","Animal Feeding","Animal Rearing","Animal Breeding","Animal Poaching","Agroforestry","Climate Smart Practices","Irrigation","Soil","Fertilizer","Permaculture","Tillage Techniques","Transplanting and Bed Making","Crops","Disease Identification","Pest and Disease Control","Pest Identification","Crop Practices","Food Processing","Food Storage","Nutrition","Crop Management","Plant Characteristics","Harvest and Postharvest","Pest and Disease Management","Propagation and Planting","Food and Water Safety","Agribusiness","Agricultural Business Management"]
subcategories.each do |subcategory|
    create_metadata(subcategory, metadata_types.find {|metadata| metadata.name == "Subcategory"}, 1)
end

subjects = ["Arts","Social Studies","Educational Tools","Health and Safety","Math","Local Resources","Science","Pharmacology","Environmental Health","Animal Health","Equipment","Manuals","Language and Reading","Midwifery","Women's Health","General Surgery","Community and Public Health","General Medicine","Pediatrics","Diagnostic Tests and Laboratory","Pharmacology","Emergency Care","Basic Sciences","Anatomy and Physiology","Standards of Practice and Patient Care","Research Methods","Dentistry","Mental Health","Rural Income Generation","الرياضيات","اللغة والآداب","العلوم الإجتماعية","الإلمام الرقمي","محتوى محلّي","Education","Training","Thaany","Learning Through Play","Ŋäc duɔ̲ɔ̲rä kɛ rɛy ŋarä","Thurɛ","Thok kɛnɛ Kuën","Mɛ̈th","Pual pua̲a̲ny kɛnɛ mal","Kuak tin te rɛy wec","Thaany gua̲th","Kuak duël gɔ̲rä","Country Specific Information","Santé et sécurité","Les Sciences","Histoire et géographie","Langage et littérature","Les Mathématiques","Information et services locale","Maîtrise de l'information et du numérique","الموارد المحلية","أدوات تعليمية","الصحة والسلامة","الفنون","المعرفة المعلوماتية والمعرفة الرقمية","دراسات اجتماعية","Artes","Recursos locales","Estudios sociales","Salud y seguridad","Ciencia","Lenguaje y lectura","Matemáticas","Sustainability","History","محو الأمية المعلوماتية ومحو الأمية الرقمية","العلوم","اللغة والقراءة","Coffee Production","Sesame Street","Digital Literacy","Information Literacy","الصحة والأمن","الصحة والأمن","الموارد المحلية","أهلاً سمسم","الاستدامة","المعرفة المعلوماتية والمعرفة الرقمية","Food Production","Plant Health","Recursos didácticos","Sustentabilidad","Gender Equity and Inclusion","Peace Corps Resources","Research Methods","Maize Production","Equidad de género","Herramientas de educación","Ciencias Sociales","Counseling","Domestic Violence and Sexual Assault","Funeral Information","Grief","Hotlines","Housing Information for Seniors","Legal Information for Victims","Informacion funeraria","Líneas de ayuda","Información de vivienda para personas mayores","Violencia doméstica y abuso sexual","Servicio de asesoramiento","Agriculture","Ibikoresho bifasha mu kwigisha","Ubuzima bw’ibihingwa","Umusaruro w’ibigori","Umusaruro w’ibiribwa","Ubuzima bw’inyamaswa","Uburyo bwo kwinjiza amafaranga mu cyaro","Ubuzima bw’ibidukikije","Ubuhinzi","Optometry","العلوم الإجتماعية","طالب الثانوية","Evidence-Based Practice"]
subjects.each do |subject|
    create_metadata(subject, metadata_types.find {|metadata| metadata.name == "Subject"}, 1)
end