WITH cte_1 AS (
    SELECT 
        url,
        audio_language_toxicity,
        metadata,
        platform,
        username,
        post_id,
        vendor,
        media_id,
        
        -- Violence-related scores
        violence.violence AS violence_score,
        violence.firearm AS violence_firearm_score,
        violence.knife AS violence_knife_score,
        violence.violent_knife AS violence_violent_knife_score,

        -- Substances-related scores
        substances.alcohol AS substances_alcohol_score,
        substances.drink AS substances_drink_score,
        substances.smoking_and_tobacco AS substances_smoking_and_tobacco_score,
        substances.marijuana AS substances_marijuana_score,
        substances.pills AS substances_pills_score,
        substances.recreational_pills AS substances_recreational_pills_score,

        -- NSFW-related scores
        nsfw.adult_content AS nsfw_adult_content_score,
        nsfw.suggestive AS nsfw_suggestive_score,
        nsfw.adult_toys AS nsfw_adult_toys_score,
        nsfw.medical AS nsfw_medical_score,
        nsfw.over_18 AS nsfw_over_18_score,
        nsfw.exposed_anus AS nsfw_exposed_anus_score,
        nsfw.exposed_armpits AS nsfw_exposed_armpits_score,
        nsfw.exposed_belly AS nsfw_exposed_belly_score,
        nsfw.covered_belly AS nsfw_covered_belly_score,
        nsfw.covered_buttocks AS nsfw_covered_buttocks_score,
        nsfw.exposed_buttocks AS nsfw_exposed_buttocks_score,
        nsfw.covered_feet AS nsfw_covered_feet_score,
        nsfw.exposed_feet AS nsfw_exposed_feet_score,
        nsfw.covered_breast_f AS nsfw_covered_breast_f_score,
        nsfw.exposed_breast_f AS nsfw_exposed_breast_f_score,
        nsfw.covered_genitalia_f AS nsfw_covered_genitalia_f_score,
        nsfw.exposed_genitalia_f AS nsfw_exposed_genitalia_f_score,
        nsfw.exposed_breast_m AS nsfw_exposed_breast_m_score,
        nsfw.exposed_genitalia_m AS nsfw_exposed_genitalia_m_score,

        -- Hate symbols-related scores
        hate_symbols.confederate_flag AS hate_symbols_confederate_flag_score,
        hate_symbols.pepe_frog AS hate_symbols_pepe_frog_score,
        hate_symbols.nazi_swastika AS hate_symbols_nazi_swastika_score,

        -- OCR language toxicity-related scores
        ocr_language_toxicity.toxicity AS ocr_language_toxicity_toxicity_score,
        ocr_language_toxicity.severe_toxicity AS ocr_language_toxicity_severe_toxicity_score,
        ocr_language_toxicity.obscene AS ocr_language_toxicity_obscene_score,
        ocr_language_toxicity.insult AS ocr_language_toxicity_insult_score,
        ocr_language_toxicity.identity_attack AS ocr_language_toxicity_identity_attack_score,
        ocr_language_toxicity.threat AS ocr_language_toxicity_threat_score,
        ocr_language_toxicity.sexual_explicit AS ocr_language_toxicity_sexual_explicit_score,

        -- Visual content-related scores
        visual_content.artistic AS visual_content_artistic_score,
        visual_content.comic AS visual_content_comic_score,
        visual_content.meme AS visual_content_meme_score,
        visual_content.screenshot AS visual_content_screenshot_score,
        visual_content.map AS visual_content_map_score,
        visual_content.poster_cover AS visual_content_poster_cover_score,
        visual_content.game_screenshot AS visual_content_game_screenshot_score,
        visual_content.face_filter AS visual_content_face_filter_score,
        visual_content.promo_info_graphic AS visual_content_promo_info_graphic_score,
        visual_content.photo AS visual_content_photo_score,

        -- Other category scores
        other.child AS other_child_score,
        other.middle_finger_gesture AS other_middle_finger_gesture_score,
        other.toy AS other_toy_score,
        other.gambling_machine AS other_gambling_machine_score,
        other.face_f AS other_face_f_score,
        other.face_m AS other_face_m_score,

    --- replace with campaign data when we have it
   'high_risk' AS violence_score_level,
    'high_risk' AS violence_firearm_score_level,
    'high_risk' AS violence_knife_score_level,
    'high_risk' AS violence_violent_knife_score_level,
    'high_risk' AS substances_alcohol_score_level,
    'high_risk' AS substances_drink_score_level,
    'high_risk' AS substances_smoking_and_tobacco_score_level,
    'high_risk' AS substances_marijuana_score_level,
    'high_risk' AS substances_pills_score_level,
    'high_risk' AS substances_recreational_pills_score_level,
    'high_risk' AS nsfw_adult_content_score_level,
    'high_risk' AS nsfw_suggestive_score_level,
    'high_risk' AS nsfw_adult_toys_score_level,
    'high_risk' AS nsfw_medical_score_level,
    'high_risk' AS nsfw_over_18_score_level,
    'high_risk' AS nsfw_exposed_anus_score_level,
    'high_risk' AS nsfw_exposed_armpits_score_level,
    'high_risk' AS nsfw_exposed_belly_score_level,
    'high_risk' AS nsfw_covered_belly_score_level,
    'high_risk' AS nsfw_covered_buttocks_score_level,
    'high_risk' AS nsfw_exposed_buttocks_score_level,
    'high_risk' AS nsfw_covered_feet_score_level,
    'high_risk' AS nsfw_exposed_feet_score_level,
    'high_risk' AS nsfw_covered_breast_f_score_level,
    'high_risk' AS nsfw_exposed_breast_f_score_level,
    'high_risk' AS nsfw_covered_genitalia_f_score_level,
    'high_risk' AS nsfw_exposed_genitalia_f_score_level,
    'high_risk' AS nsfw_exposed_breast_m_score_level,
    'high_risk' AS nsfw_exposed_genitalia_m_score_level,
    'high_risk' AS hate_symbols_confederate_flag_score_level,
    'high_risk' AS hate_symbols_pepe_frog_score_level,
    'high_risk' AS hate_symbols_nazi_swastika_score_level,
    'high_risk' AS ocr_language_toxicity_toxicity_score_level,
    'high_risk' AS ocr_language_toxicity_severe_toxicity_score_level,
    'high_risk' AS ocr_language_toxicity_obscene_score_level,
    'high_risk' AS ocr_language_toxicity_insult_score_level,
    'high_risk' AS ocr_language_toxicity_identity_attack_score_level,
    'high_risk' AS ocr_language_toxicity_threat_score_level,
    'high_risk' AS ocr_language_toxicity_sexual_explicit_score_level,
    'high_risk' AS visual_content_artistic_score_level,
    'high_risk' AS visual_content_comic_score_level,
    'high_risk' AS visual_content_meme_score_level,
    'high_risk' AS visual_content_screenshot_score_level,
    'high_risk' AS visual_content_map_score_level,
    'high_risk' AS visual_content_poster_cover_score_level,
    'high_risk' AS visual_content_game_screenshot_score_level,
    'high_risk' AS visual_content_face_filter_score_level,
    'high_risk' AS visual_content_promo_info_graphic_score_level,
    'high_risk' AS visual_content_photo_score_level,
    'high_risk' AS other_child_score_level,
    'high_risk' AS other_middle_finger_gesture_score_level,
    'high_risk' AS other_toy_score_level,
    'high_risk' AS other_gambling_machine_score_level,
    'high_risk' AS other_face_f_score_level,
    'high_risk' AS other_face_m_score_level

    FROM 
        creatorsdb.tags
),

threshold_application AS (
    SELECT *,
        -- Violence-related risks
        CASE WHEN violence_score >= 0.512 THEN 1 ELSE 0 END AS f1_violence_risk,
        CASE WHEN violence_firearm_score >= 0.900 THEN 1 ELSE 0 END AS f1_violence_firearm_risk,
        CASE WHEN violence_knife_score >= 0.810 THEN 1 ELSE 0 END AS f1_violence_knife_risk,
        CASE WHEN violence_violent_knife_score >= 0.990 THEN 1 ELSE 0 END AS f1_violence_violent_knife_risk,

        -- NSFW-related risks
        CASE WHEN nsfw_adult_content_score >= 0.355 THEN 1 ELSE 0 END AS f1_nsfw_adult_content_risk,
        CASE WHEN nsfw_suggestive_score >= 0.345 THEN 1 ELSE 0 END AS f1_nsfw_suggestive_risk,
        CASE WHEN nsfw_adult_toys_score >= 0.587 THEN 1 ELSE 0 END AS f1_nsfw_adult_toys_risk,
        CASE WHEN nsfw_medical_score >= 0.430 THEN 1 ELSE 0 END AS f1_nsfw_medical_risk,
        CASE WHEN nsfw_over_18_score >= 0.318 THEN 1 ELSE 0 END AS f1_nsfw_over_18_risk,
        CASE WHEN nsfw_exposed_anus_score >= 0.0015 THEN 1 ELSE 0 END AS f1_nsfw_exposed_anus_risk,
        CASE WHEN nsfw_exposed_armpits_score >= 0.0021 THEN 1 ELSE 0 END AS f1_nsfw_exposed_armpits_risk,
        CASE WHEN nsfw_exposed_belly_score >= 0.0009 THEN 1 ELSE 0 END AS f1_nsfw_exposed_belly_risk,
        CASE WHEN nsfw_covered_belly_score >= 0.0014 THEN 1 ELSE 0 END AS f1_nsfw_covered_belly_risk,
        CASE WHEN nsfw_covered_buttocks_score >= 0.0049 THEN 1 ELSE 0 END AS f1_nsfw_covered_buttocks_risk,
        CASE WHEN nsfw_exposed_buttocks_score >= 0.0154 THEN 1 ELSE 0 END AS f1_nsfw_exposed_buttocks_risk,
        CASE WHEN nsfw_covered_feet_score >= 0.0015 THEN 1 ELSE 0 END AS f1_nsfw_covered_feet_risk,
        CASE WHEN nsfw_exposed_feet_score >= 0.0017 THEN 1 ELSE 0 END AS f1_nsfw_exposed_feet_risk,
        CASE WHEN nsfw_covered_breast_f_score >= 0.0035 THEN 1 ELSE 0 END AS f1_nsfw_covered_breast_f_risk,
        CASE WHEN nsfw_exposed_breast_f_score >= 0.005 THEN 1 ELSE 0 END AS f1_nsfw_exposed_breast_f_risk,
        CASE WHEN nsfw_covered_genitalia_f_score >= 0.0011 THEN 1 ELSE 0 END AS f1_nsfw_covered_genitalia_f_risk,
        CASE WHEN nsfw_exposed_genitalia_f_score >= 0.0014 THEN 1 ELSE 0 END AS f1_nsfw_exposed_genitalia_f_risk,
        CASE WHEN nsfw_exposed_breast_m_score >= 0.0005 THEN 1 ELSE 0 END AS f1_nsfw_exposed_breast_m_risk,
        CASE WHEN nsfw_exposed_genitalia_m_score >= 0.0096 THEN 1 ELSE 0 END AS f1_nsfw_exposed_genitalia_m_risk,

        -- OCR language toxicity-related risks
        CASE WHEN ocr_language_toxicity_toxicity_score >= 0.900 THEN 1 ELSE 0 END AS f1_ocr_language_toxicity_toxicity_risk,
        CASE WHEN ocr_language_toxicity_severe_toxicity_score >= 0.900 THEN 1 ELSE 0 END AS f1_ocr_language_toxicity_severe_toxicity_risk,
        CASE WHEN ocr_language_toxicity_obscene_score >= 0.600 THEN 1 ELSE 0 END AS f1_ocr_language_toxicity_obscene_risk,
        CASE WHEN ocr_language_toxicity_insult_score >= 0.900 THEN 1 ELSE 0 END AS f1_ocr_language_toxicity_insult_risk,
        CASE WHEN ocr_language_toxicity_identity_attack_score >= 0.900 THEN 1 ELSE 0 END AS f1_ocr_language_toxicity_identity_attack_risk,
        CASE WHEN ocr_language_toxicity_threat_score >= 0.900 THEN 1 ELSE 0 END AS f1_ocr_language_toxicity_threat_risk,
        CASE WHEN ocr_language_toxicity_sexual_explicit_score >= 0.660 THEN 1 ELSE 0 END AS f1_ocr_language_toxicity_sexual_explicit_risk
    FROM cte_1
) 

SELECT * ,
    CASE 
        WHEN f1_violence_risk = 1 AND violence_score_level = 'minor_risk' THEN 0.25
        WHEN f1_violence_risk = 1 AND violence_score_level = 'risk' THEN 0.5
        WHEN f1_violence_risk = 1 AND violence_score_level = 'high_risk' THEN 1
        ELSE 0
    END AS violence_score_level_score,


    CASE 
        WHEN f1_violence_firearm_risk = 1 AND violence_firearm_score_level = 'minor_risk' THEN 0.25
        WHEN f1_violence_firearm_risk = 1 AND violence_firearm_score_level = 'risk' THEN 0.5
        WHEN f1_violence_firearm_risk = 1 AND violence_firearm_score_level = 'high_risk' THEN 1
        ELSE 0
    END AS violence_firearm_score_level_score,


     CASE 
        WHEN f1_violence_knife_risk = 1 AND violence_knife_score_level  = 'minor_risk' THEN 0.25
        WHEN f1_violence_knife_risk = 1 AND violence_knife_score_level  = 'risk' THEN 0.5
        WHEN f1_violence_knife_risk = 1 AND violence_knife_score_level  = 'high_risk' THEN 1
        ELSE 0
    END AS violence_knife_risk_score_level_score,


CASE 
    WHEN f1_violence_violent_knife_risk = 1 AND violence_violent_knife_score_level = 'minor_risk' THEN 0.25
    WHEN f1_violence_violent_knife_risk = 1 AND violence_violent_knife_score_level = 'risk' THEN 0.5
    WHEN f1_violence_violent_knife_risk = 1 AND violence_violent_knife_score_level = 'high_risk' THEN 1
    ELSE 0
END AS violence_violent_knife_risk_score_level_score,

CASE 
    WHEN f1_nsfw_adult_content_risk = 1 AND nsfw_adult_content_score_level = 'minor_risk' THEN 0.25
    WHEN f1_nsfw_adult_content_risk = 1 AND nsfw_adult_content_score_level = 'risk' THEN 0.5
    WHEN f1_nsfw_adult_content_risk = 1 AND nsfw_adult_content_score_level = 'high_risk' THEN 1
    ELSE 0
END AS nsfw_adult_content_risk_score_level_score,

CASE 
    WHEN f1_nsfw_suggestive_risk = 1 AND nsfw_suggestive_score_level = 'minor_risk' THEN 0.25
    WHEN f1_nsfw_suggestive_risk = 1 AND nsfw_suggestive_score_level = 'risk' THEN 0.5
    WHEN f1_nsfw_suggestive_risk = 1 AND nsfw_suggestive_score_level = 'high_risk' THEN 1
    ELSE 0
END AS nsfw_suggestive_risk_score_level_score,

CASE 
    WHEN f1_nsfw_adult_toys_risk = 1 AND nsfw_adult_toys_score_level = 'minor_risk' THEN 0.25
    WHEN f1_nsfw_adult_toys_risk = 1 AND nsfw_adult_toys_score_level = 'risk' THEN 0.5
    WHEN f1_nsfw_adult_toys_risk = 1 AND nsfw_adult_toys_score_level = 'high_risk' THEN 1
    ELSE 0
END AS nsfw_adult_toys_risk_score_level_score,

CASE 
    WHEN f1_nsfw_medical_risk = 1 AND nsfw_medical_score_level = 'minor_risk' THEN 0.25
    WHEN f1_nsfw_medical_risk = 1 AND nsfw_medical_score_level = 'risk' THEN 0.5
    WHEN f1_nsfw_medical_risk = 1 AND nsfw_medical_score_level = 'high_risk' THEN 1
    ELSE 0
END AS nsfw_medical_risk_score_level_score,

CASE 
    WHEN f1_nsfw_over_18_risk = 1 AND nsfw_over_18_score_level = 'minor_risk' THEN 0.25
    WHEN f1_nsfw_over_18_risk = 1 AND nsfw_over_18_score_level = 'risk' THEN 0.5
    WHEN f1_nsfw_over_18_risk = 1 AND nsfw_over_18_score_level = 'high_risk' THEN 1
    ELSE 0
END AS nsfw_over_18_risk_score_level_score,

CASE 
    WHEN f1_nsfw_exposed_anus_risk = 1 AND nsfw_exposed_anus_score_level = 'minor_risk' THEN 0.25
    WHEN f1_nsfw_exposed_anus_risk = 1 AND nsfw_exposed_anus_score_level = 'risk' THEN 0.5
    WHEN f1_nsfw_exposed_anus_risk = 1 AND nsfw_exposed_anus_score_level = 'high_risk' THEN 1
    ELSE 0
END AS nsfw_exposed_anus_risk_score_level_score,

CASE 
    WHEN f1_nsfw_exposed_armpits_risk = 1 AND nsfw_exposed_armpits_score_level = 'minor_risk' THEN 0.25
    WHEN f1_nsfw_exposed_armpits_risk = 1 AND nsfw_exposed_armpits_score_level = 'risk' THEN 0.5
    WHEN f1_nsfw_exposed_armpits_risk = 1 AND nsfw_exposed_armpits_score_level = 'high_risk' THEN 1
    ELSE 0
END AS nsfw_exposed_armpits_risk_score_level_score,

CASE 
    WHEN f1_nsfw_exposed_belly_risk = 1 AND nsfw_exposed_belly_score_level = 'minor_risk' THEN 0.25
    WHEN f1_nsfw_exposed_belly_risk = 1 AND nsfw_exposed_belly_score_level = 'risk' THEN 0.5
    WHEN f1_nsfw_exposed_belly_risk = 1 AND nsfw_exposed_belly_score_level = 'high_risk' THEN 1
    ELSE 0
END AS nsfw_exposed_belly_risk_score_level_score,

CASE 
    WHEN f1_nsfw_covered_belly_risk = 1 AND nsfw_covered_belly_score_level = 'minor_risk' THEN 0.25
    WHEN f1_nsfw_covered_belly_risk = 1 AND nsfw_covered_belly_score_level = 'risk' THEN 0.5
    WHEN f1_nsfw_covered_belly_risk = 1 AND nsfw_covered_belly_score_level = 'high_risk' THEN 1
    ELSE 0
END AS nsfw_covered_belly_risk_score_level_score,

CASE 
    WHEN f1_nsfw_covered_buttocks_risk = 1 AND nsfw_covered_buttocks_score_level = 'minor_risk' THEN 0.25
    WHEN f1_nsfw_covered_buttocks_risk = 1 AND nsfw_covered_buttocks_score_level = 'risk' THEN 0.5
    WHEN f1_nsfw_covered_buttocks_risk = 1 AND nsfw_covered_buttocks_score_level = 'high_risk' THEN 1
    ELSE 0
END AS nsfw_covered_buttocks_risk_score_level_score,

CASE 
    WHEN f1_nsfw_exposed_buttocks_risk = 1 AND nsfw_exposed_buttocks_score_level = 'minor_risk' THEN 0.25
    WHEN f1_nsfw_exposed_buttocks_risk = 1 AND nsfw_exposed_buttocks_score_level = 'risk' THEN 0.5
    WHEN f1_nsfw_exposed_buttocks_risk = 1 AND nsfw_exposed_buttocks_score_level = 'high_risk' THEN 1
    ELSE 0
END AS nsfw_exposed_buttocks_risk_score_level_score,

CASE 
    WHEN f1_nsfw_covered_feet_risk = 1 AND nsfw_covered_feet_score_level = 'minor_risk' THEN 0.25
    WHEN f1_nsfw_covered_feet_risk = 1 AND nsfw_covered_feet_score_level = 'risk' THEN 0.5
    WHEN f1_nsfw_covered_feet_risk = 1 AND nsfw_covered_feet_score_level = 'high_risk' THEN 1
    ELSE 0
END AS nsfw_covered_feet_risk_score_level_score,

CASE 
    WHEN f1_nsfw_exposed_feet_risk = 1 AND nsfw_exposed_feet_score_level = 'minor_risk' THEN 0.25
    WHEN f1_nsfw_exposed_feet_risk = 1 AND nsfw_exposed_feet_score_level = 'risk' THEN 0.5
    WHEN f1_nsfw_exposed_feet_risk = 1 AND nsfw_exposed_feet_score_level = 'high_risk' THEN 1
    ELSE 0
END AS nsfw_exposed_feet_risk_score_level_score,

CASE 
    WHEN f1_nsfw_covered_breast_f_risk = 1 AND nsfw_covered_breast_f_score_level = 'minor_risk' THEN 0.25
    WHEN f1_nsfw_covered_breast_f_risk = 1 AND nsfw_covered_breast_f_score_level = 'risk' THEN 0.5
    WHEN f1_nsfw_covered_breast_f_risk = 1 AND nsfw_covered_breast_f_score_level = 'high_risk' THEN 1
    ELSE 0
END AS nsfw_covered_breast_f_risk_score_level_score,

CASE 
    WHEN f1_nsfw_exposed_breast_f_risk = 1 AND nsfw_exposed_breast_f_score_level = 'minor_risk' THEN 0.25
    WHEN f1_nsfw_exposed_breast_f_risk = 1 AND nsfw_exposed_breast_f_score_level = 'risk' THEN 0.5
    WHEN f1_nsfw_exposed_breast_f_risk = 1 AND nsfw_exposed_breast_f_score_level = 'high_risk' THEN 1
    ELSE 0
END AS nsfw_exposed_breast_f_risk_score_level_score,

CASE 
    WHEN f1_nsfw_covered_genitalia_f_risk = 1 AND nsfw_covered_genitalia_f_score_level = 'minor_risk' THEN 0.25
    WHEN f1_nsfw_covered_genitalia_f_risk = 1 AND nsfw_covered_genitalia_f_score_level = 'risk' THEN 0.5
    WHEN f1_nsfw_covered_genitalia_f_risk = 1 AND nsfw_covered_genitalia_f_score_level = 'high_risk' THEN 1
    ELSE 0
END AS nsfw_covered_genitalia_f_risk_score_level_score,

CASE 
    WHEN f1_nsfw_exposed_genitalia_f_risk = 1 AND nsfw_exposed_genitalia_f_score_level = 'minor_risk' THEN 0.25
    WHEN f1_nsfw_exposed_genitalia_f_risk = 1 AND nsfw_exposed_genitalia_f_score_level = 'risk' THEN 0.5
    WHEN f1_nsfw_exposed_genitalia_f_risk = 1 AND nsfw_exposed_genitalia_f_score_level = 'high_risk' THEN 1
    ELSE 0
END AS nsfw_exposed_genitalia_f_risk_score_level_score,

CASE 
    WHEN f1_nsfw_exposed_breast_m_risk = 1 AND nsfw_exposed_breast_m_score_level = 'minor_risk' THEN 0.25
    WHEN f1_nsfw_exposed_breast_m_risk = 1 AND nsfw_exposed_breast_m_score_level = 'risk' THEN 0.5
    WHEN f1_nsfw_exposed_breast_m_risk = 1 AND nsfw_exposed_breast_m_score_level = 'high_risk' THEN 1
    ELSE 0
END AS nsfw_exposed_breast_m_risk_score_level_score,

CASE 
    WHEN f1_nsfw_exposed_genitalia_m_risk = 1 AND nsfw_exposed_genitalia_m_score_level = 'minor_risk' THEN 0.25
    WHEN f1_nsfw_exposed_genitalia_m_risk = 1 AND nsfw_exposed_genitalia_m_score_level = 'risk' THEN 0.5
    WHEN f1_nsfw_exposed_genitalia_m_risk = 1 AND nsfw_exposed_genitalia_m_score_level = 'high_risk' THEN 1
    ELSE 0
END AS nsfw_exposed_genitalia_m_risk_score_level_score

   
FROM threshold_application;



