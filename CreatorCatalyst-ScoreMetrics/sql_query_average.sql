SELECT 
platform,
username,

ROUND(AVG(CASE WHEN TRY_CAST(violence_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(violence_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS violence_score,
ROUND(AVG(CASE WHEN TRY_CAST(violence_firearm_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(violence_firearm_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS violence_firearm_score,
ROUND(AVG(CASE WHEN TRY_CAST(violence_knife_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(violence_knife_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS violence_knife_score,
ROUND(AVG(CASE WHEN TRY_CAST(violence_violent_knife_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(violence_violent_knife_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS violence_violent_knife_score,
ROUND(AVG(CASE WHEN TRY_CAST(substances_alcohol_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(substances_alcohol_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS substances_alcohol_score,
ROUND(AVG(CASE WHEN TRY_CAST(substances_drink_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(substances_drink_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS substances_drink_score,
ROUND(AVG(CASE WHEN TRY_CAST(substances_smoking_and_tobacco_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(substances_smoking_and_tobacco_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS substances_smoking_and_tobacco_score,
ROUND(AVG(CASE WHEN TRY_CAST(substances_marijuana_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(substances_marijuana_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS substances_marijuana_score,
ROUND(AVG(CASE WHEN TRY_CAST(substances_pills_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(substances_pills_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS substances_pills_score,
ROUND(AVG(CASE WHEN TRY_CAST(substances_recreational_pills_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(substances_recreational_pills_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS substances_recreational_pills_score,
ROUND(AVG(CASE WHEN TRY_CAST(nsfw_adult_content_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(nsfw_adult_content_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS nsfw_adult_content_score,
ROUND(AVG(CASE WHEN TRY_CAST(nsfw_suggestive_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(nsfw_suggestive_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS nsfw_suggestive_score,
ROUND(AVG(CASE WHEN TRY_CAST(nsfw_adult_toys_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(nsfw_adult_toys_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS nsfw_adult_toys_score,
ROUND(AVG(CASE WHEN TRY_CAST(nsfw_medical_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(nsfw_medical_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS nsfw_medical_score,
ROUND(AVG(CASE WHEN TRY_CAST(nsfw_over_18_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(nsfw_over_18_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS nsfw_over_18_score,
ROUND(AVG(CASE WHEN TRY_CAST(nsfw_exposed_anus_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(nsfw_exposed_anus_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS nsfw_exposed_anus_score,
ROUND(AVG(CASE WHEN TRY_CAST(nsfw_exposed_armpits_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(nsfw_exposed_armpits_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS nsfw_exposed_armpits_score,
ROUND(AVG(CASE WHEN TRY_CAST(nsfw_exposed_belly_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(nsfw_exposed_belly_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS nsfw_exposed_belly_score,
ROUND(AVG(CASE WHEN TRY_CAST(nsfw_covered_belly_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(nsfw_covered_belly_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS nsfw_covered_belly_score,
ROUND(AVG(CASE WHEN TRY_CAST(nsfw_covered_buttocks_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(nsfw_covered_buttocks_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS nsfw_covered_buttocks_score,
ROUND(AVG(CASE WHEN TRY_CAST(nsfw_exposed_buttocks_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(nsfw_exposed_buttocks_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS nsfw_exposed_buttocks_score,
ROUND(AVG(CASE WHEN TRY_CAST(nsfw_covered_feet_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(nsfw_covered_feet_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS nsfw_covered_feet_score,
ROUND(AVG(CASE WHEN TRY_CAST(nsfw_exposed_feet_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(nsfw_exposed_feet_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS nsfw_exposed_feet_score,
ROUND(AVG(CASE WHEN TRY_CAST(nsfw_covered_breast_f_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(nsfw_covered_breast_f_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS nsfw_covered_breast_f_score,
ROUND(AVG(CASE WHEN TRY_CAST(nsfw_exposed_breast_f_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(nsfw_exposed_breast_f_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS nsfw_exposed_breast_f_score,
ROUND(AVG(CASE WHEN TRY_CAST(nsfw_covered_genitalia_f_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(nsfw_covered_genitalia_f_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS nsfw_covered_genitalia_f_score,
ROUND(AVG(CASE WHEN TRY_CAST(nsfw_exposed_genitalia_f_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(nsfw_exposed_genitalia_f_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS nsfw_exposed_genitalia_f_score,
ROUND(AVG(CASE WHEN TRY_CAST(nsfw_exposed_breast_m_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(nsfw_exposed_breast_m_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS nsfw_exposed_breast_m_score,
ROUND(AVG(CASE WHEN TRY_CAST(nsfw_exposed_genitalia_m_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(nsfw_exposed_genitalia_m_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS nsfw_exposed_genitalia_m_score,
ROUND(AVG(CASE WHEN TRY_CAST(hate_symbols_confederate_flag_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(hate_symbols_confederate_flag_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS hate_symbols_confederate_flag_score,
ROUND(AVG(CASE WHEN TRY_CAST(hate_symbols_pepe_frog_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(hate_symbols_pepe_frog_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS hate_symbols_pepe_frog_score,
ROUND(AVG(CASE WHEN TRY_CAST(hate_symbols_nazi_swastika_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(hate_symbols_nazi_swastika_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS hate_symbols_nazi_swastika_score,
ROUND(AVG(CASE WHEN TRY_CAST(ocr_language_toxicity_toxicity_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(ocr_language_toxicity_toxicity_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS ocr_language_toxicity_toxicity_score,
ROUND(AVG(CASE WHEN TRY_CAST(ocr_language_toxicity_severe_toxicity_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(ocr_language_toxicity_severe_toxicity_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS ocr_language_toxicity_severe_toxicity_score,
ROUND(AVG(CASE WHEN TRY_CAST(ocr_language_toxicity_obscene_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(ocr_language_toxicity_obscene_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS ocr_language_toxicity_obscene_score,
ROUND(AVG(CASE WHEN TRY_CAST(ocr_language_toxicity_insult_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(ocr_language_toxicity_insult_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS ocr_language_toxicity_insult_score,
ROUND(AVG(CASE WHEN TRY_CAST(ocr_language_toxicity_identity_attack_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(ocr_language_toxicity_identity_attack_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS ocr_language_toxicity_identity_attack_score,
ROUND(AVG(CASE WHEN TRY_CAST(ocr_language_toxicity_threat_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(ocr_language_toxicity_threat_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS ocr_language_toxicity_threat_score,
ROUND(AVG(CASE WHEN TRY_CAST(ocr_language_toxicity_sexual_explicit_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(ocr_language_toxicity_sexual_explicit_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS ocr_language_toxicity_sexual_explicit_score,
ROUND(AVG(CASE WHEN TRY_CAST(visual_content_artistic_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(visual_content_artistic_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS visual_content_artistic_score,
ROUND(AVG(CASE WHEN TRY_CAST(visual_content_comic_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(visual_content_comic_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS visual_content_comic_score,
ROUND(AVG(CASE WHEN TRY_CAST(visual_content_meme_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(visual_content_meme_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS visual_content_meme_score,
ROUND(AVG(CASE WHEN TRY_CAST(visual_content_screenshot_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(visual_content_screenshot_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS visual_content_screenshot_score,
ROUND(AVG(CASE WHEN TRY_CAST(visual_content_map_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(visual_content_map_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS visual_content_map_score,
ROUND(AVG(CASE WHEN TRY_CAST(visual_content_poster_cover_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(visual_content_poster_cover_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS visual_content_poster_cover_score,
ROUND(AVG(CASE WHEN TRY_CAST(visual_content_game_screenshot_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(visual_content_game_screenshot_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS visual_content_game_screenshot_score,
ROUND(AVG(CASE WHEN TRY_CAST(visual_content_face_filter_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(visual_content_face_filter_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS visual_content_face_filter_score,
ROUND(AVG(CASE WHEN TRY_CAST(visual_content_promo_info_graphic_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(visual_content_promo_info_graphic_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS visual_content_promo_info_graphic_score,
ROUND(AVG(CASE WHEN TRY_CAST(visual_content_photo_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(visual_content_photo_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS visual_content_photo_score,
ROUND(AVG(CASE WHEN TRY_CAST(other_child_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(other_child_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS other_child_score,
ROUND(AVG(CASE WHEN TRY_CAST(other_middle_finger_gesture_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(other_middle_finger_gesture_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS other_middle_finger_gesture_score,
ROUND(AVG(CASE WHEN TRY_CAST(other_toy_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(other_toy_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS other_toy_score,
ROUND(AVG(CASE WHEN TRY_CAST(other_gambling_machine_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(other_gambling_machine_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS other_gambling_machine_score,
ROUND(AVG(CASE WHEN TRY_CAST(other_face_f_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(other_face_f_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS other_face_f_score,
ROUND(AVG(CASE WHEN TRY_CAST(other_face_m_score AS DECIMAL(10,2)) IS NOT NULL THEN CAST(other_face_m_score AS DECIMAL(10,2)) ELSE NULL END), 2) AS other_face_m_score

FROM "creatorsdb"."score_metrics" 
group by platform, username
limit 20;